# Understanding Container Storage Layers

In OpenShift, containers and images are composed of **overlays** (layers) managed by
the `containers/storage` library (used by CRI-O and Podman). These are stored on each
node under:

```text
/var/lib/containers/storage/
├── overlay/              <- actual layer filesystem content (the bulk data)
├── overlay-containers/   <- container metadata + writable layers
├── overlay-images/       <- image metadata
└── overlay-layers/       <- layer metadata (parent chain, digests, sizes)
```

This document explains what is stored in each folder and how to correlate their
information together. This is the model that the `sos4ocp.sh` script relies on for the
`-D` (disk pressure) and `-o`/`-m` filtering options.

---

## What is stored in each folder

### `overlay-images/`

The **image metadata store**. It does _not_ hold image content — only the bookkeeping.

* `images.json` — the master list of every image. Each entry contains:
  * `id` — the image ID
  * `names` — the tags / digests (e.g. `registry.redhat.io/...`)
  * `layer` — the **top layer ID** of the image
  * timestamps and a reference to the image's "big data" (config / manifest)
* Per-image subdirectories (named by image ID) containing the **image config blob**
  (`sha256:...` — the OCI/Docker config JSON with env, entrypoint and the
  `rootfs.diff_ids` list) and the **manifest**.

### `overlay-layers/`

The **layer metadata store** (metadata, not the bulk data).

* `layers.json` — the master list of every layer. Each entry has:
  * `id` — the layer's storage ID
  * `parent` — the ID of the layer below it (this is what chains layers into a stack)
  * `diff-digest` / `diff-size` / `compressed-diff-digest` — the uncompressed `diff_id`,
    its uncompressed size, and the compressed digest used to match against image manifests
  * `uidset` / `gidset`, mount flags, etc.
* `*.tar-split.gz` files — data used to reconstruct exact tar streams for each layer.

### `overlay/`

The **actual layer filesystem content** — the bulk data. One subdirectory per layer ID:

```text
overlay/<layerID>/
├── diff/      <- the actual files added/changed in this layer
├── link       <- a short symlink name for this layer
├── lower      <- the ordered chain of lower layers (short link names)
├── work/      <- overlayfs workdir (for mounted/active layers)
└── merged/    <- the unified mountpoint (only when mounted)
```

* `overlay/l/` — a directory of short symlinks (e.g. `l/ABCDEF... -> ../<layerID>/diff`).
  OverlayFS limits the length of the `lowerdir=` mount option, so each layer gets a short
  name here, and the `lower` file references those short names.

### `overlay-containers/`

The **container metadata + writable layer store**.

* `containers.json` — every container: container `id`, `names`, the **image ID** it was
  created from (`image`), and the container's own **writable layer ID** (`layer`).
* Per-container subdirectories with the runtime `config.json` (OCI spec), `spec`, etc.

---

## How to interconnect the information

The chain of references, from a running container down to the files on disk:

```text
overlay-containers/containers.json
   ├─ container.image  ──────────────►  overlay-images/images.json (image.id)
   └─ container.layer  ──┐                         │
                         │              image.layer (top layer)
                         ▼                         ▼
              overlay-layers/layers.json  ◄────────┘
                   layer.id
                   layer.parent ──► layer.parent ──► ... (walk down to base)
                         │
                         ▼
              overlay/<layerID>/diff/   (actual files for that layer)
```

Concretely, to go from a running container to its files:

1. **Container → image**: In `overlay-containers/containers.json`, find your container
   by name/ID. Read its `image` field → that is the image ID. Read its `layer` field →
   that is the container's _writable_ layer.
2. **Image → top layer**: In `overlay-images/images.json`, find that image ID. Its
   `layer` field is the **top read-only layer** of the image.
3. **Walk the layer chain**: In `overlay-layers/layers.json`, start at a layer ID and
   follow `parent` repeatedly until `parent` is empty. That ordered chain is the full
   image stack (base layer at the bottom).
4. **Layer → content**: For each layer ID in the chain, the real files are under
   `overlay/<layerID>/diff/`. The `overlay/<layerID>/lower` file (via the `l/` short
   symlinks) encodes that same stack as the actual overlayfs `lowerdir`.
5. **Layer ↔ image manifest**: To match on-disk layers back to the digests in an image
   manifest, use `diff-digest` in `layers.json` — it equals a `diff_id` in the image
   config's `rootfs.diff_ids` (found in the image config blob under
   `overlay-images/<imageID>/`).

### Quick correlation cheatsheet

| You have       | Look in                                | Field                            | Gets you                     |
|----------------|----------------------------------------|----------------------------------|------------------------------|
| Container name | `overlay-containers/containers.json`   | `names` → `id`, `image`, `layer` | image ID + writable layer    |
| Image ID       | `overlay-images/images.json`           | `id` → `layer`, `names`          | tags + top layer             |
| Layer ID       | `overlay-layers/layers.json`           | `id` → `parent`, `diff-digest`   | next layer down + digest     |
| Layer ID       | `overlay/<id>/`                        | `diff/`, `lower`                 | actual files + stack order   |
| Layer digest   | image config `rootfs.diff_ids`         | matches `diff-digest`            | ties layer to the manifest   |

---

## Notes in a SOSREPORT context

* In a sosreport you generally have the JSON files (`images.json`, `layers.json`,
  `containers.json`) and directory listings, but **not** the `diff/` contents — so you
  can reconstruct the _relationships and layer sizes_ but not inspect the actual files.
* `diff-size` in `layers.json` is the uncompressed size of each layer, which is what
  lets you compute per-image / per-container disk usage by walking the parent chain and
  summing — watching for **shared parent layers** so you do not double-count.
* The live equivalent of all this is `podman inspect` / `crictl inspect` plus
  `podman system df -v`, but the JSON files let you do it offline.
* The file `/var/lib/containers/storage/overlay-layers/layers.json` is required for the
  layer-level correlation. See the note in the [README](README.md) about including it in
  the sosreport archive.

---

## Identifying an overlay with `sos4ocp.sh -o`

The `-o <OVERLAY_ID>` option correlates a storage overlay directory name back to what
owns it, using the model above:

1. It first checks the running PODs and containers (`crictl_inspectp_*` /
   `crictl_inspect_*`, matching `.info.runtimeSpec.root.path`). If a POD or container
   owns the overlay, its details are displayed as usual.
2. If **no** running POD/container owns it, the overlay is classified as a **storage
   layer** and a report is printed describing:
   * the **type** — _Container writable layer_, _Image top layer_,
     _Image intermediate (shared) layer_, or _Orphaned / dangling layer_;
   * the layer facts from `layers.json` (`id`, `parent`, direct children,
     `diff-digest`, `diff-size`, `created`);
   * a **"Trees including this layer"** overview table — a layer can belong to several
     trees (it may be shared by multiple images, and/or be the root of an orphaned
     branch). Each row shows the tree number, type (`Image` or `Orphan branch`), the full
     image/root ID (so it can be reused with other options), and details. Image trees are
     one row each (`Image <full-id> <tag> (layer X/Y)`) — use `-D` / `-m` to drill into an
     image;
   * for the **orphaned branch**, a detailed layer listing is printed below the table,
     from the top of the orphan stack down to the base, each layer with its full ID, size
     and creation date. Each row is typed `ORPHAN` (red) or `IN-USE` (green — e.g. a shared
     base kept for context), and the overlay passed to `-o` has its ID highlighted in
     yellow — useful to see when the orphaned branch was created.

   See [Reclaiming space](#reclaiming-space-pruning-images-and-orphaned-layers) below for
   how to actually free this space (reclamation is done at the image level, not per layer).

### How ownership is determined (graceful fallback)

Because `overlay-images/images.json` and `overlay-containers/containers.json` are not
collected in a standard sosreport, the script determines image ownership by matching the
layer's `diff-digest` against the `rootfs.diff_ids` list inside the `crictl_inspecti_*`
image inspect files. When `images.json` / `containers.json` **are** present in the
archive, they are used as an additional, more authoritative source.

An **orphaned / dangling layer** is one present in `layers.json` whose `diff-digest`
(and that of its whole parent/child chain) is not referenced by any present image or
container — typically a leftover from an image that was removed but whose layers have not
been garbage-collected. These are common culprits in `diskPressure` investigations.

### Searching for all orphaned layers

Instead of a specific overlay ID, pass the keyword `orphan` (or `orphans`) to `-o`:

```bash
sos4ocp.sh -s <SOSREPORT_PATH> -o orphan
```

This scans the whole `layers.json`, groups the orphaned layers per tree (connected
orphan layers sharing the same top-most orphan ancestor — the parent relation is a
forest), and for each tree displays the **bottom** and **top** layer (Type, Layer ID,
Layer size, Created), the number of orphaned layers in the tree and the sum of their
`diff-size`, followed by the grand totals across all trees. Trees are sorted by size
(largest first) to surface the biggest branches for `diskPressure` triage.

---

## Reclaiming space (pruning images and orphaned layers)

`sos4ocp.sh` is a read-only diagnostic for an (offline) sosreport — it never deletes
anything. The commands below are what an engineer would run **on the live node** to
reclaim space. Layers are **not** removed individually: the storage driver only frees a
layer once no image (or container) references it anymore. So reclamation is done at the
**image** level, and a layer shared by several images is only freed once **all** of those
images are removed.

> **Caution:** these are node-level operations that affect the container runtime and any
> workload on that node. On OpenShift, prefer draining/cordoning the node first, and let
> kubelet's automatic image garbage collection do the work when possible (it prunes unused
> images under disk pressure, governed by `imageGCHighThresholdPercent` /
> `imageGCLowThresholdPercent` in the kubelet config). Always confirm an image is not
> needed before removing it.

### Images still in use (the `Image` trees in `-o` / `-D`)

These belong to a present image and are only freed when that image is removed:

```bash
crictl images                 # list images with IDs and sizes
crictl rmi <IMAGE_ID>         # remove one specific image (use the full ID from -o)
crictl rmi --prune            # remove all images not referenced by any pod/container
```

`crictl rmi --prune` is the CRI-O equivalent of pruning unused images; kubelet runs the
same kind of cleanup automatically when the node crosses its image-GC disk threshold.

### Orphaned / dangling layers (the `Orphan branch` tree in `-o`)

Orphaned layers are **not** attached to any present image, so `crictl rmi` cannot target
them directly — there is no image to remove. They are leftovers from an image that was
deleted (or a pull/build that was interrupted) whose layers were not garbage-collected.
Options to clean them up, in order of preference:

```bash
# Podman shares the same containers/storage backend as CRI-O on the node.
podman system check --repair     # detect and remove damaged / unreferenced layers (when available)
podman image prune -a            # remove all images not used by a container (frees their layers)
podman system prune -a           # images + build cache + unused data
```

If orphaned layers persist after the above (a known effect of interrupted operations on
very large images, e.g. AI `modelcar` images), the last resort — on a **drained** node —
is to stop the runtime and reset the storage, which forces a clean re-pull of everything:

```bash
# Drain the node first, then on the node:
systemctl stop kubelet crio
podman system reset -f           # wipes /var/lib/containers/storage (all images/containers)
systemctl start crio kubelet
```

Use the full layer IDs printed by `-o` (and the image IDs from the tree table) to confirm
what each command would affect before running it.
