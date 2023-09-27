# sos4ocp

This bash script will display PDO and containers details for a specific POD within a SOSREPORT

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

Simply run the script with the desired option

```bash
sos4ocp.sh [-s <SOSREPORT_PATH>] [-n <PODNAME>|-i <PODID>|-c <CONTAINER_NAME>] [-h]
```

If you provide the full PODID, the script will trunk it to 13 characters.

#### Script Options

using the `-h` option will display the help and provide the list of the available options, and the version of the script.

```text
usage: sos4ocp.sh [-s <SOSREPORT_PATH>] [-n <PODNAME>|-i <PODID>|-c <CONTAINER_NAME>|-g <CGROUP>] [-h]
|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| Options | Description                                                     | [Default]                                                                     |
|---------|-----------------------------------------------------------------|-------------------------------------------------------------------------------|
|      -s | Path to access the SOSREPORT base folder                        | <Current folder> [.]                                                          |
|      -n | Name of the POD                                                 | null (if POD/CONTAINER options are missing, provide choice between all PODs)  |
|      -i | UID of the POD                                                  | null (if POD/CONTAINER options are missing, provide choice between all PODs)  |
|      -c | Name of a CONTAINER                                             | null (if POD/CONTAINER options are missing, provide choice between all PODs)  |
|      -g | Specific cgroup                                                 | null                                                                          |
|---------|-----------------------------------------------------------------|-------------------------------------------------------------------------------|
|         | Additional Options:                                             |                                                                               |
|---------|-----------------------------------------------------------------|-------------------------------------------------------------------------------|
|      -h | display this help and check for updated version                 |                                                                               |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------|

Current Version: X.X.X
```
