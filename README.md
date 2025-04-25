# sos4ocp

This bash script will display POD and containers details for a specific POD within a SOSREPORT

## Installation and updates

### Requirements

None

### Installation

* pull the repository

```text
git clone https://github.com/vlours/sos4ocp
```

* Create the alias `sos4ocp` for `sos4ocp.sh` in your .bashrc profile (_optional_)

```bash
echo -e "\nalias sos4ocp=${PWD}/sos4ocp/sos4ocp.sh" >> ${HOME}/.bashrc
source ${HOME}/.bashrc
```

### Update to latest version (_based on the alias_)

To update to the latest version, you simply have to pull the script from the repository.

```bash
sos4ocp_dir=$(dirname $(alias sos4ocp | cut -d"'" -f2)); cd ${sos4ocp_dir}; git pull origin main; cd -
```

### Remove the script (_based on the alias_)

```bash
sos4ocp_dir=$(dirname $(alias mg_check | cut -d"'" -f2))
if [[ -d ${sos4ocp_dir} ]]; then rm ${sos4ocp_dir}; fi
sed -i -e "/alias sos4ocp/d" ${HOME}/.bashrc
```

## Usage

### Basic Usage

* Simply run the script with the desired option to display the POD/Container(s) details

    ```bash
    sos4ocp.sh [-s <SOSREPORT_PATH>] [-p <PODNAME>|-i <PODID>|-I <containerID>|-c <CONTAINER_NAME>|-n <NAMESPACE>|-g <CGROUP>|-o <CONTAINER_OVERLAY>|-u <POD_UID>] [-h]
    ```

* Or the following command to display sort the containers by the desired statistic

    ```bash
    sos4ocp.sh [-s <SOSREPORT_PATH>] -S <name|cpu|mem|disk|inodes|state|attempt> [-h]
    ```

*Notes:*

* If you provide the full PODID, the script will trunk it to 13 characters.
* If you use the `-c`, `-g` , `-o` or `-I` option using the container details, the container will be highlighted in the menu with `<<<<< Matching Filter` at the end of the line.

  ```text
  [8]     Inspect Container:  kube-apiserver-cert-syncer  (64916b3d43187)  0  0.04  32.34MB  8.192kB  16      <<<<< Matching Filter
  ```

### Script Options

using the `-h` option will display the help and provide the list of the available options, and the version of the script.

```text
usage: sos4ocp.sh [-s <SOSREPORT_PATH>] [-p <PODNAME>|-i <PODID>|-I <containerID>|-c <CONTAINER_NAME>|-n <NAMESPACE>|-g <CGROUP>|-o <CONTAINER_OVERLAY>|-u <POD_UID>] [-h]
usage: sos4ocp.sh [-s <SOSREPORT_PATH>] -S <name|cpu|mem|disk|inodes|state|attempt> [-h]

if none of the filtering parameters is used, the script will display a menu with a list of the available PODs from the sosreport.

|-----------------------------------------------------------------------------------------------------------------|
| Options | Description                                                                    | [Default]            |
|---------|--------------------------------------------------------------------------------|----------------------|
|      -s | Path to access the SOSREPORT base folder                                       | <Current folder> [.] |
|      -p | Name of the POD                                                                | null                 |
|      -i | UID of the POD                                                                 | null                 |
|      -I | UID of the container                                                           | null                 |
|      -c | Name of a CONTAINER                                                            | null                 |
|      -n | NAMESPACE related to PODs                                                      | null                 |
|      -g | CGROUP attached to a POD or Container                                          | null                 |
|      -o | Storage OVERLAY ID attached to a Container                                     | null                 |
|      -u | storage UID attached to a POD                                                  | null                 |
|      -S | Display all containers stats by [name,cpu,mem,disk,inodes,state,attempt]       | null                 |
|---------|--------------------------------------------------------------------------------|----------------------|
|         | Examples:                                                                      |                      |
|         |  - CGROUP for POD:        kubepods-burstable-pod<ID>                           |                      |
|         |  - CGROUP for Container:  crio-<ID>                                            |                      |
|         |  - OVERLAY:               /var/lib/containers/storage/overlay/<OVERLAY>/merged |                      |
|         |  - POD_UID:               /var/lib/kubelet/pods/<POD_UID>/                     |                      |
|---------|--------------------------------------------------------------------------------|----------------------|
|         | Additional Options:                                                            |                      |
|---------|--------------------------------------------------------------------------------|----------------------|
|      -h | display this help and check for updated version                                |                      |
|-----------------------------------------------------------------------------------------------------------------|

Current Version: X.Y.Z
```
