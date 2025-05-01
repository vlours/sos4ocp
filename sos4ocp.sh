#!/bin/bash
##################################################################
# Script       # sos4ocp.sh
# Description  # Display POD and related containers details
# @VERSION     # 1.2.0
##################################################################
# Changelog.md # List the modifications in the script.
# README.md    # Describes the repository usage
##################################################################

##### Functions
# Help
fct_help(){
  Script=$(which $0 2>${STD_ERR})
  if [[ "${Script}" != "bash" ]] && [[ ! -z ${Script} ]]
  then
    ScriptName=$(basename $0)
  fi
  echo -e "usage: ${cyantext}${ScriptName} [-s <SOSREPORT_PATH>] [-p <PODNAME>|-i <PODID>|-I <containerID>|-c <CONTAINER_NAME>|-n <NAMESPACE>|-g <CGROUP>|-o <CONTAINER_OVERLAY>|-u <POD_UID>] ${purpletext}[-h]${resetcolor}"
  echo -e "usage: ${cyantext}${ScriptName} [-s <SOSREPORT_PATH>] -S <name|cpu|mem|disk|inodes|state|attempt> ${purpletext}[-h]${resetcolor}"
  echo -e "\nif none of the filtering parameters is used, the script will display a menu with a list of the available PODs from the sosreport.\n"
  OPTION_TAB=8
  DESCR_TAB=78
  DEFAULT_TAB=21
  printf "|%${OPTION_TAB}s---%-${DESCR_TAB}s---%-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" "Options" "Description" "[Default]"
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-s" "Path to access the SOSREPORT base folder" "<Current folder> [.]"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-p" "Name of the POD" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-i" "UID of the POD" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-I" "UID of the container" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-c" "Name of a CONTAINER" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-n" "NAMESPACE related to PODs" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-g" "CGROUP attached to a POD or Container" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-o" "Storage OVERLAY ID attached to a Container" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-u" "storage UID attached to a POD" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-S" "Display all containers stats by [name,cpu,mem,disk,inodes,state,attempt]" "null"
  printf "|%${OPTION_TAB}s-|-%-${DESCR_TAB}s-|-%-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" "" "Examples:" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | ${yellowtext}%-${DESCR_TAB}s${resetcolor} | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "" " - CGROUP for POD:        kubepods-burstable-pod<ID>" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | ${yellowtext}%-${DESCR_TAB}s${resetcolor} | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "" " - CGROUP for Container:  crio-<ID>" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | ${yellowtext}%-${DESCR_TAB}s${resetcolor} | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "" " - OVERLAY:               /var/lib/containers/storage/overlay/<OVERLAY>/merged" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | ${yellowtext}%-${DESCR_TAB}s${resetcolor} | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "" " - POD_UID:               /var/lib/kubelet/pods/<POD_UID>/" ""
  printf "|%${OPTION_TAB}s-|-%-${DESCR_TAB}s-|-%-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" "" "Additional Options:" ""
  printf "|%${OPTION_TAB}s-|-%-${DESCR_TAB}s-|-%-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|${purpletext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" "-h" "display this help and check for updated version" ""
  printf "|%${OPTION_TAB}s---%-${DESCR_TAB}s---%-${DEFAULT_TAB}s|\n" |tr \  '-'

  Script=$(which $0 2>${STD_ERR})
  if [[ "${Script}" != "bash" ]] && [[ ! -z ${Script} ]]
  then
    VERSION=$(grep "@VERSION" ${Script} 2>${STD_ERR} | grep -Ev "VERSION=" | cut -d'#' -f3)
    VERSION=${VERSION:-" N/A"}
  fi
  echo -e "\nCurrent Version:\t${VERSION}"
}

# Titles
fct_title() {
  echo -e "\n====== $* ======"
}
fct_title_details() {
  echo -e "\n##### $* #####"
}

# Display the POD Inspect
fct_inspect(){
  case ${1} in
    "container")
      FILEPATH="${CONTAINERPATH}/crictl_inspect_${2}"
      ;;
    "log")
      FILEPATH="${LOGPATH}/crictl_logs_-t_${2}"
      ;;
    "pod")
      FILEPATH="${PODPATH}/crictl_inspectp_${2}"
      ;;
  esac
  FILENAME=$(ls -1 ${FILEPATH}* 2>/dev/null)
  if [[ -z ${FILENAME} ]]
  then
    echo -e "\nWARN: Unable to locate a ${1} file in the matching the PATH: ${FILEPATH}*"
  else
    FCT_CMD="less ${FILENAME}"
    echo -e "\n${FCT_CMD}"
    ${FCT_CMD}
  fi
}

# Display the Main Menu
fct_display_menu(){
clear
REP=""
while [[ ${REP} != [qQ] ]]
do
  NUM=0
  fct_title "POD Details"
  echo -e "${POD_HEADER}\n${POD_DETAILS}" | column -t | sed -e "s/About_\([a-z]*\)_\([a-z]*\) ago/About \1 \2 ago/" -e "s/\([0-9]*\)_\([a-z]*\)_ago/\1 \2 ago/" -e "s/POD_ID/POD ID/"
  fct_title "Containers Details"
  echo -e "${CONTAINER_HEADER}\n${CONTAINER_DETAILS}" | column -t | sed -e "s/About_\([a-z]*\)_\([a-z]*\)_ago/About \1 \2 ago/" -e "s/\([0-9]*\)_\([a-z]*\)_ago/\1 \2 ago/" -e "s/POD_ID/POD ID/" -e "s/\(Exited\)/${redtext}\1${resetcolor}/" -e "s/\(Running\)/${greentext}\1${resetcolor}/"
  echo
  echo -e "OPTION|AVAILABLE ACTION|OBJECT NAME|REFERENCE|ATTEMPT|CPU USAGE (%)|MEM USAGE|DISK USAGE|INODES|\n------|----------------|-----------|---------|-------|-------------|---------|----------|------|\n$(while [[ ${NUM} -lt ${OPTION_NUM} ]]
  do
    echo "[$[NUM+1]]|$(echo ${LIST_OPTION[${NUM}]} | cut -d',' -f1)"
    NUM=$[NUM+1]
  done)\n[q]|Quit" | column -t -s'|'
  printf "Choice: "
  read REP
  if ([[ ${REP} != [qQ] ]] && (! [[ ${REP} =~ ^[0-9]+$ ]])) || ([[ ${REP} =~ ^[0-9]+$ ]] && ([[ ${REP} -gt ${OPTION_NUM} ]] || [[ ${REP} -le 0 ]]))
  then
    clear
    echo "Invalid Choice: ${REP}"
  else
    if [[ ${REP} != [qQ] ]]
    then
      $(echo ${LIST_OPTION[$[REP-1]]} | cut -d',' -f2-)
      echo "Press Enter to return to the menu"
      read
      clear
    fi
  fi
done
}

# Display the POD list Menu
fct_pod_list_menu(){
REP=""
POD_NUM=$(echo ${#POD_LIST[@]})
if [[ ${POD_NUM} == 0 ]]
then
  echo -e "Unable to retrieve the list of POD. Please review the content of the file: ${CRIO_PATH}/crictl_pods\n" && fct_help && exit 15
fi
while ([[ ${REP} != [qQ] ]] &&  [[ ${PODID} == "null" ]])
do
  NUM=0
  echo -e ",POD_ID,POD_NAME,NAMESPACE\n$(while [[ ${NUM} -lt ${POD_NUM} ]]
  do
    echo "[$[NUM+1]],$(echo ${POD_LIST[${NUM}]})"
    NUM=$[NUM+1]
  done)\n[q],Quit" | column -t -s','
  printf "Choice: "
  read REP
  if ([[ ${REP} != [qQ] ]] && (! [[ ${REP} =~ ^[0-9]+$ ]])) || ([[ ${REP} =~ ^[0-9]+$ ]] && ([[ ${REP} -gt ${POD_NUM} ]] || [[ ${REP} -le 0 ]]))
  then
    clear
    echo "Invalid Choice: ${REP}"
  else
      if [[ ${REP} != [qQ] ]]
      then
        PODID=$(echo ${POD_LIST[$[REP-1]]} | cut -d',' -f1)
      else
        exit 0
      fi
  fi
done
}

# Extract POD reference from container ID
fct_extract_from_container_id(){
if [[ $(head -1 ${CRIO_PATH}/crictl_ps_-a | awk '{print $NF}') == "ID" ]]
then
  POD_IDS_LIST=($(awk -v containerid=${CONTAINERID} '{if($1 == containerid){printf "%s ",$NF}}' ${CRIO_PATH}/crictl_ps_-a | sort -u | awk '{printf "%s ",$(NF-1)}'))
else
  POD_IDS_LIST=($(awk -v containerid=${CONTAINERID} '{if($1 == containerid){printf "%s ",$(NF-1)}}' ${CRIO_PATH}/crictl_ps_-a | sort -u | awk '{printf "%s ",$(NF-1)}'))
fi
}

# Collect the containers details
fct_container_details(){
CONTAINER_DETAILS=${CONTAINER_DETAILS:-$(awk -v podid=${PODID} '{if($(NF-1) == podid){print}}' ${CRIO_PATH}/crictl_ps_-a | sed -e "s/About \([a-z]*\) \([a-z]*\) ago/About_\1_\2_ago/" -e "s/\([0-9]*\) \([a-z]*\) ago/\1_\2_ago/")}
if [[ -z ${CONTAINER_DETAILS} ]]
then
  CONTAINER_DETAILS=$(awk -v podid=${PODID} '{if($(NF) == podid){print}}' ${CRIO_PATH}/crictl_ps_-a | sed -e "s/About \([a-z]*\) \([a-z]*\) ago/About_\1_\2_ago/" -e "s/\([0-9]*\) \([a-z]*\) ago/\1_\2_ago/")
  CONTAINER_IDS=($(echo "${CONTAINER_DETAILS}" |awk '{printf "%s,%s ",$1,$(NF-2)}'))
else
  if [[ -z ${CONTAINER_IDS} ]]
  then
    CONTAINER_IDS=($(echo "${CONTAINER_DETAILS}" |awk '{printf "%s,%s ",$1,$(NF-3)}'))
  fi
fi
}

#Retrieve container statistic
fct_container_statistic(){
  #Check if the container name is included in the crictl_stats data
  if [[ $(awk 'BEGIN{namepresence="false"}{if($2 == "NAME"){namepresence="true"}}END{print namepresence}' ${CRIO_PATH}/crictl_stats) == "true" ]]
  then
    awk -v container_id=$1 '{if($1 == container_id){stats=$3"|"$4"|"$5"|"$6}}END{if (stats != ""){printf stats}else{printf "-|-|-|-"}}' ${CRIO_PATH}/crictl_stats
  else
    awk -v container_id=$1 '{if($1 == container_id){stats=$2"|"$3"|"$4"|"$5}}END{if (stats != ""){printf stats}else{printf "-|-|-|-"}}' ${CRIO_PATH}/crictl_stats
  fi
}

#Display the Container's Process details
fct_container_processes(){
  container_id=$1
  FILEPATH="${CONTAINERPATH}/crictl_inspect_${container_id}"
  FILENAME=$(ls -1 "${FILEPATH}"* 2>/dev/null)
  WARN=0
  if [[ -z ${FILENAME} ]]
  then
    echo -e "\nWARN: Unable to locate a inspect file in the matching the PATH: ${FILEPATH}*"
  else
    Container_cgroup=$(jq -r '.info.runtimeSpec.linux.cgroupsPath' ${FILENAME} | sed -e "s/:crio:/\/crio-/")
    PSFAUXWWW=${SOSREPORT_PATH}/sos_commands/process/ps_auxfwww
    PSAUXWWWM=${SOSREPORT_PATH}/sos_commands/process/ps_auxwwwm
    PS_GROUP=${SOSREPORT_PATH}/sos_commands/process/ps_axo_pid_ppid_user_group_lwp_nlwp_start_time_comm_cgroup
    if [[ ! -f ${PS_GROUP} ]]
    then
      echo -e "\WARN: File ${PS_GROUP} is missing" && WARN=$[WARN + 1]
    fi
    if [[ ! -f ${PSFAUXWWW} ]]
    then
      if [[ ! -f ${PSAUXWWWM} ]]
      then
        echo -e "\WARN: Files ${PSFAUXWWW} and ${PSAUXWWWM} are missing" && WARN=$[WARN + 1]
      else
        echo -e "\INFO: File ${PSFAUXWWW} is missing, using file ${PSAUXWWWM} instead"
        PSFAUXWWW=${PSAUXWWWM}
      fi
    fi
    if [[ ${WARN} == 0 ]]
    then
      echo -e "\nList of processes attached to the cgroup: ${Container_cgroup}"
      PROCESS_LIST="$(grep ${Container_cgroup} ${PS_GROUP} 2>/dev/null| awk '{printf "|^[a-zA-Z0-9+ ]*"$1"|^[a-zA-Z0-9+ ]*"$2}')"
      grep -E "^USER${PROCESS_LIST}" ${PSFAUXWWW} | less
    fi
  fi
}

##### Main

# Set a default STD_ERR, which can be replaced for debugging to "/dev/stderr"
STD_ERR="${STD_ERR:-/dev/null}"

# Color list
graytext=${graytext:-"\x1B[30m"}
redtext=${redtext:-"\x1B[31m"}
greentext=${greentext:-"\x1B[32m"}
yellowtext=${yellowtext:-"\x1B[33m"}
bluetext=${bluetext:-"\x1B[34m"}
purpletext=${purpletext:-"\x1B[35m"}
cyantext=${cyantext:-"\x1B[36m"}
whitetext=${whitetext:-"\x1B[37m"}
resetcolor=${resetcolor:-"\x1B[0m"}

# Getops
if [[ $# != 0 ]]
then
  if [[ $1 == "-" ]] || [[ $1 =~ ^[a-zA-Z0-9] ]]
  then
    echo -e "Invalid option: ${1}\n"
    fct_help && exit 1
  fi
  OPTNUM=0
  while getopts :i:I:p:c:g:n:o:u:s:S:h arg; do
  case $arg in
      i)
        PODID=${OPTARG}
        OPTNUM=$[OPTNUM + 1]
        PODFILTER="ID"
        ;;
      I)
        CONTAINERID=${OPTARG:0:13}
        OPTNUM=$[OPTNUM + 1]
        PODFILTER="CONTAINERID"
        ;;
      p)
        PODNAME=${OPTARG}
        OPTNUM=$[OPTNUM + 1]
        PODFILTER="NAME"
        ;;
      c)
        CONTAINERNAME=${OPTARG}
        OPTNUM=$[OPTNUM + 1]
        PODFILTER="CONTAINER"
        ;;
      g)
        CGROUP=${OPTARG}
        OPTNUM=$[OPTNUM + 1]
        PODFILTER="CGROUP"
        ;;
      n)
        NAMESPACE=${OPTARG}
        OPTNUM=$[OPTNUM + 1]
        PODFILTER="NAMESPACE"
        ;;
      o)
        OVERLAY=${OPTARG}
        OPTNUM=$[OPTNUM + 1]
        PODFILTER="OVERLAY"
        ;;
      u)
        PODUID=${OPTARG}
        OPTNUM=$[OPTNUM + 1]
        PODFILTER="PODUID"
        ;;
      s)
        SOSREPORT_PATH=$(echo ${OPTARG} | sed -e "s/\/*$//")
        ;;
      S)
        SORT_KEY=${OPTARG:-"name"}
        SORTFILTER=''
        case ${SORT_KEY} in
          name)
            SORT_VALUE=2
            ;;
          state)
            SORT_VALUE=5
            ;;
          attempt)
            SORT_VALUE=7
            SORTFILTER='n'
            ;;
          cpu)
            SORT_VALUE=8
            SORTFILTER='h'
            ;;
          mem)
            SORT_VALUE=9
            SORTFILTER='h'
            ;;
          disk)
            SORT_VALUE=10
            SORTFILTER='h'
            ;;
          inodes)
            SORT_VALUE=11
            SORTFILTER='n'
            ;;
          *)
            echo "Err: invalid sorting key '${SORT_KEY}' for the container statistic"
            fct_help && exit 5
            ;;
        esac
        PODFILTER="STATISTIC"
        OPTNUM=$[OPTNUM + 1]
        ;;
      h)
        fct_help && exit 0
        ;;
      ?)
        echo -e "Invalid option\n"
        fct_help && exit 1
        ;;
  esac
  done
fi
if [[ ${OPTNUM} -ge 2 ]]
then
  echo -e "Too many arguments!\n"
  fct_help && exit 3
fi
SOSREPORT_PATH=${SOSREPORT_PATH:-.}
CRIO_PATH=${SOSREPORT_PATH}/sos_commands/crio
PODNAME=${PODNAME:-"null"}
PODID=${PODID:-"null"}
CONTAINERNAME=${CONTAINERNAME:-"null"}
CGROUP=${CGROUP:-"null"}
NAMESPACE=${NAMESPACE:-"null"}

# Check if the PATH is valid
if [[ ! -d ${CRIO_PATH} ]]
then

  if [[ -d "$(ls -1d ${SOSREPORT_PATH}/*sosreport* 2>${STD_ERR}| head -1)/sos_commands/crio" ]]
  then
    CRIO_PATH="$(ls -1d ${SOSREPORT_PATH}/*sosreport* 2>${STD_ERR}| head -1)/sos_commands/crio"
  else
    echo "Err: Unable to find the crio folder in the SOSREPORT PATH. Invalid SOSREPORT PATH: ${SOSREPORT_PATH}"
    fct_help && exit 5
  fi
fi

if [[ -d ${CRIO_PATH}/containers/logs/ ]]
then
  LOGPATH="${CRIO_PATH}/containers/logs"
  CONTAINERPATH="${CRIO_PATH}/containers"
else
  if [[ -d ${CRIO_PATH}/containers/ ]]
  then
    LOGPATH="${CRIO_PATH}/containers"
    CONTAINERPATH="${CRIO_PATH}/containers"
  else
    LOGPATH="${CRIO_PATH}"
    CONTAINERPATH="${CRIO_PATH}"
  fi
fi
if [[ -d ${CRIO_PATH}/pods/ ]]
then
  PODPATH="${CRIO_PATH}/pods"
else
  PODPATH="${CRIO_PATH}/"
fi

clear

if [[ ${OPTNUM} == 0 ]]
then
  POD_LIST=($(awk '{if(($1 != "POD") && ($1 !~ "^time=")){printf "%s,%s,%s,%s\n",$1,$(NF-3),$(NF-2),$(NF-4)}}' ${CRIO_PATH}/crictl_pods | sort -r -k 4 -k3 -t',' | awk '{printf "%s ",$0}'))
  fct_pod_list_menu
else
  if [[ "${PODID}" == "null" ]] && [[ "${PODNAME}" == "null" ]]
  then
    case ${PODFILTER} in
      "CONTAINER")
        POD_IDS_LIST=($(awk -v containername=${CONTAINERNAME} '{if($(NF-2) == containername){printf "%s ",$NF}else if($(NF-3) == containername){print $(NF-1)}}' ${CRIO_PATH}/crictl_ps_-a | sort -u | awk '{printf "%s ",$(NF-1)}'))
        echo -e "List of PODs including the container: ${CONTAINERNAME}\n"
        ;;
      "CONTAINERID")
        fct_extract_from_container_id
        echo -e "List of PODs including the container: ${CONTAINERNAME}\n"
        ;;
      "CGROUP")
        POD_IDS_LIST=($(jq -r --arg cgroup "${CGROUP}" '.? | select(.info.runtimeSpec.linux.cgroupsPath | test($cgroup)) | "\(.status.id[0:13]) "' $(file ${CRIO_PATH}/pods/crictl_inspectp_* | grep -E "JSON data" | cut -d':' -f1)))
        if [[ -z ${POD_IDS_LIST} ]]
        then
          CONTAINERID=$(jq -r --arg cgroup "$(echo ${CGROUP} | sed -e "s/crio-//")" '.? | select(.info.runtimeSpec.linux.cgroupsPath | test($cgroup)) | "\(.status.id[0:13])"' $(file ${CRIO_PATH}/containers/crictl_inspect* | grep -E "JSON data" | cut -d':' -f1))
          fct_extract_from_container_id
        fi
        echo -e "List of PODs including the cgroup: ${CGROUP}\n"
        ;;
      "NAMESPACE")
        POD_IDS_LIST=($(awk -v pod_namespace=${NAMESPACE} '{if($(NF-2) == pod_namespace){printf "%s ",$1}}' ${CRIO_PATH}/crictl_pods))
        echo -e "List of PODs from the namespce: ${NAMESPACE}\n"
        ;;
      "STATISTIC")
        if [[ -f ${CRIO_PATH}/crictl_stats ]]
        then
          POD_DETAILS=$(grep -Ev "^POD" ${CRIO_PATH}/crictl_pods)
          CONTAINER_DETAILS=$(awk '{if($1 != "CONTAINER"){print}}' ${CRIO_PATH}/crictl_ps_-a | sed -e "s/About \([a-z]*\) \([a-z]*\) ago/About_\1_\2_ago/" -e "s/\([0-9]*\) \([a-z]*\) ago/\1_\2_ago/")
          if [[ $(head -1 ${CRIO_PATH}/crictl_ps_-a | awk '{print $NF}') == "POD" ]]
          then
            CONTAINER_IDS=($(echo "${CONTAINER_DETAILS}" |awk '{printf "%s|%s|%s|%s|%s|%s|%s ",$7,$8,$1,$5,$4,$3,$6}'))
          else
            CONTAINER_IDS=($(echo "${CONTAINER_DETAILS}" |awk '{printf "%s|%s|%s|%s|%s|%s|%s ",$7,"-",$1,$5,$4,$3,$6}'))
          fi
        else
          echo -e "Unable to find the stats file: ${CRIO_PATH}/crictl_stats." && fct_help && exit 7
        fi
        ;;
        "OVERLAY")
        POD_IDS_LIST=($(jq -r --arg overlay "${OVERLAY}" '.? | select(.info.runtimeSpec.root.path | test($overlay)) | "\(.status.id[0:13]) "' $(file ${CRIO_PATH}/pods/crictl_inspectp_* | grep -E "JSON data" | cut -d':' -f1)))
        if [[ -z ${POD_IDS_LIST} ]]
        then
          CONTAINERID=$(jq -r --arg overlay "$(echo ${OVERLAY} | sed -e "s/crio-//")" '.? | select(.info.runtimeSpec.root.path | test($overlay)) | "\(.status.id[0:13])"' $(file ${CRIO_PATH}/containers/crictl_inspect* | grep -E "JSON data" | cut -d':' -f1))
          fct_extract_from_container_id
        fi
        echo -e "List of PODs including the overlay: ${OVERLAY}\n"
        ;;
        "PODUID")
          POD_IDS_LIST=($(jq -r --arg poduid "${PODUID}" '.? | select(.status.metadata.uid == $poduid) | "\(.status.id[0:13]) "' $(file ${CRIO_PATH}/pods/crictl_inspectp_* | grep -E "JSON data" | cut -d':' -f1)))
          echo -e "List of PODs including the POD_UID: ${PODUID}\n"
        ;;
    esac
    if [[ ${#POD_IDS_LIST[@]} == 1 ]]
    then
      PODID=${POD_IDS_LIST[0]}
    else
      if [[ ${#POD_IDS_LIST[@]} -ge 2 ]]
      then
        POD_LIST=($(awk '{if(($1 != "POD") && ($1 !~ "^time=")){printf "%s,%s,%s,%s\n",$1,$(NF-3),$(NF-2),$(NF-4)}}' ${CRIO_PATH}/crictl_pods | sort -r -k 4 -k3 -t',' | awk -F',' -v pod_ids="$(echo "${POD_IDS_LIST[@]}")" 'BEGIN{split(pod_ids,pod_array," ")}{for(ID in pod_array){if($1 == pod_array[ID]){printf "%s ",$0}}}'))
        fct_pod_list_menu
      fi
    fi
  fi
fi

# Trunking the PODID to 13 characters
PODID=$(echo ${PODID}  | cut -c1-13)

# Collect the POD Details & set the missing value
POD_HEADER=$(awk '($1 == "POD"){print}' ${CRIO_PATH}/crictl_pods | sed -e "s/POD ID/POD_ID/")
POD_DETAILS=${POD_DETAILS:-$(awk -v podid=${PODID} -v podname=${PODNAME} '{if(($1 == podid) || ($(NF-3) == podname)){print} }' ${CRIO_PATH}/crictl_pods | sed -e "s/About \([a-z]*\) \([a-z]*\) ago/About_\1_\2_ago/" -e "s/\([0-9]*\) \([a-z]*\) ago/\1_\2_ago/")}
if [[ -z "${POD_DETAILS}" ]]
then
  echo -e "Unable to find a POD from the specified parameter\n" && fct_help && exit 10
fi
if [[ ${PODID} == "null" ]]
then
  PODID=$(echo "${POD_DETAILS}" | awk '{print $1}')
fi
if [[ ${PODNAME} == "null" ]]
then
  PODNAME=$(echo "${POD_DETAILS}" | awk '{print $(NF-3)}')
fi
# Collect the Container(s) details and create an Array with the IDs
fct_container_details

if [[ ${PODFILTER} == "STATISTIC" ]]
then
  NUM=0
  OPTION_NUM=$(echo ${#CONTAINER_IDS[@]})
  echo -e "POD ID|POD NAME|CONTAINER ID|CONTAINER NAME|STATE|CREATED|ATTEMPT|CPU USAGE (%)|MEM USAGE|DISK USAGE|INODES|\n------|---------|------------|--------------|-----|-------|-------|-------------|---------|----------|------|\n$(while [[ ${NUM} -lt ${OPTION_NUM} ]]
  do
    CONTAINER_ID=$(echo ${CONTAINER_IDS[${NUM}]} | cut -d'|' -f3)
    echo "$(echo ${CONTAINER_IDS[${NUM}]} | cut -d',' -f1)|$(fct_container_statistic ${CONTAINER_ID})" | sed -e "s/About_\([a-z]*\)_\([a-z]*\)_ago/About \1 \2 ago/" -e "s/\([0-9]*\)_\([a-z]*\)_ago/\1 \2 ago/"
    NUM=$[NUM+1]
  done | sort -${SORTFILTER}r -t'|' -k${SORT_VALUE})" | column -t -s'|'
else
  # Create the List of option  for the Menu
  CONTAINER_HEADER=$(awk '($1 == "CONTAINER"){print}' ${CRIO_PATH}/crictl_ps_-a | sed -e "s/POD ID/POD_ID/")
  LIST_OPTION=("${purpletext}Inspect POD:|${PODNAME}|(${PODID})${resetcolor},fct_inspect "pod" ${PODID}")
  for CONTAINER_INFO in ${CONTAINER_IDS[*]}
  do
    CONTAINER_ID=$(echo ${CONTAINER_INFO} | cut -d',' -f1)
    CONTAINER_NAME=$(echo ${CONTAINER_INFO} | cut -d',' -f2)
    FILEPATH="${CONTAINERPATH}/crictl_inspect_${CONTAINER_ID}"
    FILENAME=$(ls -1 ${FILEPATH}* 2>/dev/null)
    if [[ -f ${FILENAME} ]]
    then
      ATTEMPTS=$(jq -r '.status.metadata.attempt' ${FILENAME} 2>/dev/null)
    fi
    ATTEMPTS=${ATTEMPTS:-"N/A"}
    if ([[ ! -z ${CONTAINERID} ]] && [[ ${CONTAINERID} == ${CONTAINER_ID} ]]) || ([[ ! -z ${CONTAINERNAME} ]] && [[ ${CONTAINERNAME} == ${CONTAINER_NAME} ]])
    then
      LIST_OPTION+=("${cyantext}Inspect Container:|${CONTAINER_NAME}|(${CONTAINER_ID})|${ATTEMPTS}|$(fct_container_statistic ${CONTAINER_ID})|<<<<< Matching Filter${resetcolor},fct_inspect "container" ${CONTAINER_ID}")
    else
      LIST_OPTION+=("${cyantext}Inspect Container:|${CONTAINER_NAME}|(${CONTAINER_ID})|${ATTEMPTS}|$(fct_container_statistic ${CONTAINER_ID})${resetcolor},fct_inspect "container" ${CONTAINER_ID}")
    fi
    LIST_OPTION+=("${greentext}Display Container log:|${CONTAINER_NAME}|(${CONTAINER_ID})${resetcolor},fct_inspect "log" ${CONTAINER_ID}")
    LIST_OPTION+=("${yellowtext}Display Container proc:|${CONTAINER_NAME}|(${CONTAINER_ID})${resetcolor},fct_container_processes ${CONTAINER_ID}")
  done
  OPTION_NUM=$(echo ${#LIST_OPTION[@]})
  fct_display_menu
fi
exit 0
