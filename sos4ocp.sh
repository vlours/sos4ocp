#!/bin/bash
##################################################################
# Script       # sos4ocp.sh
# Description  # Display POD and related containers details
# @VERSION     # 0.4.1
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
  echo -e "usage: ${cyantext}${ScriptName} [-s <SOSREPORT_PATH>] [-p <PODNAME>|-i <PODID>|-c <CONTAINER_NAME>|-n <NAMESPACE>|-g <CGROUP>] ${purpletext}[-h]${resetcolor}"
  echo -e "\nif none of the filtering parameters is used, the script will display a menu with a list of the available PODs from the sosreport.\n"
  OPTION_TAB=8
  DESCR_TAB=63
  DEFAULT_TAB=78
  printf "|%${OPTION_TAB}s---%-${DESCR_TAB}s---%-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" "Options" "Description" "[Default]"
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-s" "Path to access the SOSREPORT base folder" "<Current folder> [.]"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-p" "Name of the POD" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-i" "UID of the POD" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-c" "Name of a CONTAINER" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-n" "NAMESPACE related to PODs" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-g" "CGROUP attached to a POD" "null"
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
fct_inspectp(){
  FCT_CMD="less ${CRIO_PATH}/pods/crictl_inspectp_${1}*"
  echo -e "\n${FCT_CMD}"
  ${FCT_CMD}
}

# Display the Container Inspect
fct_inspectc(){
  FCT_CMD="less ${CRIO_PATH}/containers/crictl_inspect_${1}*"
  echo -e "\n${FCT_CMD}"
  ${FCT_CMD}
}

# Dispaly the Container Log
fct_container_log(){
  FCT_CMD="less ${CRIO_PATH}/containers/logs/crictl_logs_-t_${1}*"
  echo -e "\n${FCT_CMD}"
  ${FCT_CMD}
}

# Display the Main Menu
fct_display_menu(){
clear
REP=""
while [[ ${REP} != [qQ] ]]
do
  NUM=0
  fct_title "POD Details"
  echo "$POD_DETAILS" | column -t | sed -e "s/\([0-9]*\)_\([a-z]*\)_ago/\1 \2 ago/"
  fct_title "Containers Details"
  echo "$CONTAINER_DETAILS" | column -t | sed -e "s/\([0-9]*\)_\([a-z]*\)_ago/\1 \2 ago/"
  echo
  echo -e "$(while [[ ${NUM} -lt ${OPTION_NUM} ]]
  do
    echo "[$[NUM+1]] - $(echo ${LIST_OPTION[${NUM}]} | cut -d',' -f1)"
    NUM=$[NUM+1]
  done)\n[q] - Quit" | column -t -s'|'
  printf "Choice: "
  read REP
  if ([[ ${REP} != [qQ] ]] && [[ ${REP} != [0-9]* ]]) || ([[ ${REP} == [0-9]* ]] && ([[ ${REP} -gt ${OPTION_NUM} ]] || [[ ${REP} -le 0 ]]))
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
while [[ ${REP} == "" ]]
do
  NUM=0
  echo -e ",POD_ID,POD_NAME,NAMESPACE\n$(while [[ ${NUM} -lt ${POD_NUM} ]]
  do
    echo "[$[NUM+1]],$(echo ${POD_LIST[${NUM}]})"
    NUM=$[NUM+1]
  done)" | column -t -s','
  printf "Choice: "
  read REP
  if ([[ ${REP} != [0-9]* ]]) || ([[ ${REP} == [0-9]* ]] && ([[ ${REP} -gt ${POD_NUM} ]] || [[ ${REP} -le 0 ]]))
  then
    clear
    echo "Invalid Choice: ${REP}"
    REP=""
  else
      PODID=$(echo ${POD_LIST[$[REP-1]]} | cut -d',' -f1)
  fi
done
}

##### Main

# Set a default STD_ERR, which can be replaced for debugging to "/dev/stderr"
STD_ERR="${STD_ERR:-/dev/null}"

# Getops
if [[ $# != 0 ]]
then
  if [[ $1 == "-" ]] || [[ $1 =~ ^[a-zA-Z0-9] ]]
  then
    echo -e "Invalid option: ${1}\n"
    fct_help && exit 1
  fi
  OPTNUM=0
  while getopts :i:n:c:s:g:p:h arg; do
  case $arg in
      i)
        PODID=${OPTARG}
        OPTNUM=$[OPTNUM + 1]
        PODFILTER="ID"
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
      s)
        SOSREPORT_PATH=$(echo ${OPTARG} | sed -e "s/\/*$//")
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

clear

if [[ ${OPTNUM} == 0 ]]
then
  POD_LIST=($(awk '{if(($1 != "POD") && ($1 !~ "^time=")){printf "%s,%s,%s ",$1,$(NF-3),$(NF-2)}}' ${CRIO_PATH}/crictl_pods))
  fct_pod_list_menu
else
  if [[ "${PODID}" == "null" ]] && [[ "${PODNAME}" == "null" ]]
  then
    case $PODFILTER in
      "CONTAINER")
        POD_IDS_LIST=($(awk -v containername=${CONTAINERNAME} '{if($(NF-2) == containername){printf "%s ",$NF}else if($(NF-3) == containername){print $(NF-1)}}' ${CRIO_PATH}/crictl_ps_-a | sort -u | awk '{printf "%s ",$(NF-1)}'))
        echo -e "List of PODs including the container: ${CONTAINERNAME}\n"
        ;;
      "CGROUP")
        POD_IDS_LIST=($(jq -r --arg cgroup "${CGROUP}" '.? | select(.info.runtimeSpec.linux.cgroupsPath | test($cgroup)) | "\(.status.id[0:13]) "' $(file ${CRIO_PATH}/pods/crictl_inspectp_* | grep -E "JSON data" | cut -d':' -f1)))
        echo -e "List of PODs including the cgroup: ${CGROUP}\n"
        ;;
      "NAMESPACE")
        POD_IDS_LIST=($(awk -v pod_namespace=${NAMESPACE} '{if($(NF-2) == pod_namespace){printf "%s ",$1}}' ${CRIO_PATH}/crictl_pods))
        echo -e "List of PODs from the namespce: ${NAMESPACE}\n"
        ;;
    esac
    if [[ ${#POD_IDS_LIST[@]} == 1 ]]
    then
      PODID=${POD_IDS_LIST[0]}
    else
      if [[ ${#POD_IDS_LIST[@]} -ge 2 ]]
      then
        POD_LIST=($(awk -v pod_ids="$(echo "${POD_IDS_LIST[@]}")" 'BEGIN{split(pod_ids,pod_array," ")}{for(ID in pod_array){if($1 == pod_array[ID]){printf "%s,%s,%s ",$1,$(NF-3),$(NF-2)}}}' ${CRIO_PATH}/crictl_pods))
        fct_pod_list_menu
      fi
    fi
  fi
fi

# Trunking the PODID to 13 characters
PODID=$(echo ${PODID}  | cut -c1-13)

# Collect the POD Details & set the missing value
POD_DETAILS=$(awk -v podid=${PODID} -v podname=${PODNAME} '{if(($1 == podid) || ($(NF-3) == podname)){print} }' ${CRIO_PATH}/crictl_pods | sed -e "s/\([0-9]*\) \([a-z]*\) ago/\1_\2_ago/")
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
CONTAINER_DETAILS=$(awk -v podid=${PODID} '{if($(NF-1) == podid){print}}' ${CRIO_PATH}/crictl_ps_-a | sed -e "s/\([0-9]*\) \([a-z]*\) ago/\1_\2_ago/")
if [[ -z ${CONTAINER_DETAILS} ]]
then
  CONTAINER_DETAILS=$(awk -v podid=${PODID} '{if($(NF) == podid){print}}' ${CRIO_PATH}/crictl_ps_-a | sed -e "s/\([0-9]*\) \([a-z]*\) ago/\1_\2_ago/")
  CONTAINER_IDS=($(echo "${CONTAINER_DETAILS}" |awk '{printf "%s,%s ",$1,$(NF-2)}'))
else
  CONTAINER_IDS=($(echo "${CONTAINER_DETAILS}" |awk '{printf "%s,%s ",$1,$(NF-3)}'))
fi



# Create the List of option  for the Menu
LIST_OPTION=("Inspect POD:|${PODNAME}|(${PODID}),fct_inspectp ${PODID}")
for CONTAINER_INFO in ${CONTAINER_IDS[*]}
do
  CONTAINER_ID=$(echo ${CONTAINER_INFO} | cut -d',' -f1)
  CONTAINER_NAME=$(echo ${CONTAINER_INFO} | cut -d',' -f2)
  LIST_OPTION+=("Inspect Container:|${CONTAINER_NAME}|(${CONTAINER_ID}),fct_inspectc ${CONTAINER_ID}")
  LIST_OPTION+=("Display Container log:|${CONTAINER_NAME}|(${CONTAINER_ID}),fct_container_log ${CONTAINER_ID}")
done
OPTION_NUM=$(echo ${#LIST_OPTION[@]})
fct_display_menu
exit 0
