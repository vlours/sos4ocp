#!/bin/bash
##################################################################
# Script       # sos4ocp.sh
# Description  # Display POD and related containers details
# @VERSION     # 1.0.2
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
  echo -e "usage: ${cyantext}${ScriptName} [-s <SOSREPORT_PATH>] [-p <PODNAME>|-i <PODID>|-c <CONTAINER_NAME>|-n <NAMESPACE>|-g <CGROUP>|-S <name|cpu|mem|disk|inodes>] ${purpletext}[-h]${resetcolor}"
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
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-S" "Display all containers stats by [name,cpu,mem,disk,inodes]" "null"
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
      FILEPATH="${CRIO_PATH}/containers/crictl_inspect_${2}"
      ;;
    "log")
      if [[ -d ${CRIO_PATH}/containers/logs/ ]]
      then
        FILEPATH="${CRIO_PATH}/containers/logs/crictl_logs_-t_${2}"
      else
        FILEPATH="${CRIO_PATH}/containers/crictl_logs_-t_${2}"
      fi
      ;;
    "pod")
      FILEPATH="${CRIO_PATH}/pods/crictl_inspectp_${2}"
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
  echo -e "${CONTAINER_HEADER}\n${CONTAINER_DETAILS}" | column -t | sed -e "s/About_\([a-z]*\)_\([a-z]*\)_ago/About \1 \2 ago/" -e "s/\([0-9]*\)_\([a-z]*\)_ago/\1 \2 ago/" -e "s/POD_ID/POD ID/"
  echo
  echo -e "OPTION|AVAILABLE ACTION|OBJECT NAME|REFERENCE|CPU USAGE (%)|MEM USAGE|DISK USAGE|INODES|\n------|----------------|-----------|---------|-------------|---------|----------|------|\n$(while [[ ${NUM} -lt ${OPTION_NUM} ]]
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

# Collect the container details
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
  awk -v container_id=$1 'BEGIN{if($2 == "NAME"){Include_Name=true}}{if($1 == container_id){if(Include_Name==true){stats=$3"|"$4"|"$5"|"$6}else{stats=$2"|"$3"|"$4"|"$5}}}END{if (stats != ""){printf stats}else{printf "-|-|-|-"}}' ${CRIO_PATH}/crictl_stats
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
  while getopts :i:n:c:s:g:p:S:h arg; do
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
      S)
        SORT_KEY=${OPTARG:-"name"}
        case ${SORT_KEY} in
          name)
            SORT_VALUE=2
            ;;
          cpu)
            SORT_VALUE=8
            ;;
          mem)
            SORT_VALUE=9
            ;;
          disk)
            SORT_VALUE=10
            ;;
          inodes)
            SORT_VALUE=11
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
      "CGROUP")
        POD_IDS_LIST=($(jq -r --arg cgroup "${CGROUP}" '.? | select(.info.runtimeSpec.linux.cgroupsPath | test($cgroup)) | "\(.status.id[0:13]) "' $(file ${CRIO_PATH}/pods/crictl_inspectp_* | grep -E "JSON data" | cut -d':' -f1)))
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
  done | sort -hr -t'|' -k${SORT_VALUE})" | column -t -s'|'
else
  # Create the List of option  for the Menu
  CONTAINER_HEADER=$(awk '($1 == "CONTAINER"){print}' ${CRIO_PATH}/crictl_ps_-a | sed -e "s/POD ID/POD_ID/")
  LIST_OPTION=("Inspect POD:|${PODNAME}|(${PODID}),fct_inspect "pod" ${PODID}")
  for CONTAINER_INFO in ${CONTAINER_IDS[*]}
  do
    CONTAINER_ID=$(echo ${CONTAINER_INFO} | cut -d',' -f1)
    CONTAINER_NAME=$(echo ${CONTAINER_INFO} | cut -d',' -f2)
    LIST_OPTION+=("Inspect Container:|${CONTAINER_NAME}|(${CONTAINER_ID})|$(fct_container_statistic ${CONTAINER_ID}),fct_inspect "container" ${CONTAINER_ID}")
    LIST_OPTION+=("Display Container log:|${CONTAINER_NAME}|(${CONTAINER_ID}),fct_inspect "log" ${CONTAINER_ID}")
  done
  OPTION_NUM=$(echo ${#LIST_OPTION[@]})
  fct_display_menu
fi
exit 0
