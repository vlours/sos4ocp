#!/bin/bash
##################################################################
# Script       # sos4ocp.sh
# Description  # Display POD and related containers details
# @VERSION     # 1.4.2
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
  echo -e "usage: ${cyantext}${ScriptName} [-s <SOSREPORT_PATH>] [-p <PODNAME>|-i <PODID>|-I <containerID>|-c <CONTAINER_NAME>|-m <imageID>|-n <NAMESPACE>|-g <CGROUP>|-o <CONTAINER_OVERLAY>|-P <PROCESS_ID>|-u <POD_UID>] ${purpletext}[-h|-v]${resetcolor}"
  echo -e "usage: ${cyantext}${ScriptName} [-s <SOSREPORT_PATH>] -S <name|cpu|mem|disk|inodes|state|attempt> | -D <sum|both|layers> ${purpletext}[-h|-v]${resetcolor}"
  echo -e "\nif none of the filtering parameters is used, the script will display a menu with a list of the available PODs from the sosreport.\n"
  OPTION_TAB=8
  DESCR_TAB=115
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
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-m" "Image ID attached to a Container (can also be used as a filter with -D option)" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-P" "Process ID (PID) of a process attached to a Container" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-u" "storage UID attached to a POD" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-S" "Display all containers stats by [name,cpu,mem,disk,inodes,state,attempt]" "null"
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "-D" "Display the image sizes (<sum>), layers details (<layers>) or <both>, to help troubleshoot diskPressure conditions" "null"
  printf "|%${OPTION_TAB}s-|-%-${DESCR_TAB}s-|-%-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" "" "Examples:" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | ${yellowtext}%-${DESCR_TAB}s${resetcolor} | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "" " - CGROUP for POD:        kubepods-burstable-pod<ID>" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | ${yellowtext}%-${DESCR_TAB}s${resetcolor} | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "" " - CGROUP for Container:  crio-<ID>" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | ${yellowtext}%-${DESCR_TAB}s${resetcolor} | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "" " - OVERLAY:               /var/lib/containers/storage/overlay/<OVERLAY>/merged" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | ${yellowtext}%-${DESCR_TAB}s${resetcolor} | ${greentext}%-${DEFAULT_TAB}s${resetcolor}|\n" "" " - POD_UID from storage:  /var/lib/kubelet/pods/<POD_UID>/" ""
  printf "|%${OPTION_TAB}s-|-%-${DESCR_TAB}s-|-%-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" "" "Additional Options:" ""
  printf "|%${OPTION_TAB}s-|-%-${DESCR_TAB}s-|-%-${DEFAULT_TAB}s|\n" |tr \  '-'
  printf "|${purpletext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" "-h" "display this helpn" ""
  printf "|${purpletext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | %-${DEFAULT_TAB}s|\n" "-v" "display the version and check for updates" ""
  printf "|%${OPTION_TAB}s---%-${DESCR_TAB}s---%-${DEFAULT_TAB}s|\n" |tr \  '-'

  echo "" && fct_version
}

fct_version() {
  Script=$(which $0 2>${STD_ERR})
  if [[ "${Script}" != "bash" ]] && [[ ! -z ${Script} ]]
  then
    VERSION=$(grep "@VERSION" ${Script} 2>${STD_ERR} | grep -Ev "VERSION=" | cut -d'#' -f3)
    VERSION=${VERSION:-" N/A"}
    RANDOM_CHECK=$(awk -v min=1 -v max=${MAX_RANDOM} 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
    if [[ ${RANDOM_CHECK} == 1 ]]
    then
      My_TTY=$(who am i | awk '{print $2}')
      NEW_VERSION=$(curl -Ns --connect-timeout 2 --max-time 4 "${SOURCE_RAW_URL}" 2>${STD_ERR} | grep "@VERSION" | grep -Ev "VERSION=" | cut -d'#' -f3)
      NEW_VERSION=${NEW_VERSION:-" N/A"}
      if [[ "${VERSION}" != "${NEW_VERSION}" ]] && [[ "${NEW_VERSION}" != " N/A" ]] && [[ "${VERSION}" != " N/A" ]]
      then
        UPDATE_MSG="Current Version:\t${redtext}${VERSION}${resetcolor} | Please considere to update. Thanks\nAvailable Version:\t${NEW_VERSION}\n[Source: ${bluetext}${SOURCE_URL}${resetcolor}]"
      else
        if [[ "${NEW_VERSION}" == " N/A" ]] && [[ "${VERSION}" != " N/A" ]]
        then
          SCRIPT_mtime=$(ls -l ${ls_option} $(which $0) | awk '{print $(NF-1)}' | sed -e "s/+//")
          Time_Gap=$[$Current_time - $SCRIPT_mtime]
          if [[ ${Time_Gap} -gt ${Time_Gap_Alert} ]]
          then
            UPDATE_MSG="Current Version:\t${redtext}${VERSION}${resetcolor} | The script $(basename ${0}) is older (${Time_Gap}) than $[${Time_Gap_Alert} / 86400] days.\nPlease consider to update it if a new version is available. Thanks\n[Source: ${bluetext}${SOURCE_URL}${resetcolor}]"
          fi
        else
          UPDATE_MSG="Current Version:\t${greentext}${VERSION}${resetcolor} | The script is up-to-date. Thanks"
        fi
      fi
      echo -e "$UPDATE_MSG"
    fi
  fi
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
    echo -e "\n${yellowtext}WARN: Unable to locate a ${1} file in the matching the PATH: ${FILEPATH}*${resetcolor}\n"
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
  done)\n[q]|Quit" | column -ts'|' | sed -e "s/Inspect POD:.*/${purpletext}&${resetcolor}/" -e "s/Inspect Container:.*/${cyantext}&${resetcolor}/" -e "s/Display Container log:.*/${greentext}&${resetcolor}/" -e "s/Display Container proc:.*/${yellowtext}&${resetcolor}/"
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
  echo -e " ,POD_ID,POD_NAME,NAMESPACE,STATE\n$(while [[ ${NUM} -lt ${POD_NUM} ]]
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
  POD_IDS_LIST=($(awk -v containerid=${CONTAINERID} -v position=${PODID_POSITION} '{if($1 == containerid){print $(NF-position)}}' ${CRIO_PATH}/crictl_ps_-a 2>/dev/null | sort -u | awk '{printf "%s ",$0}'))
}

# Collect the containers details
fct_container_details(){
CONTAINER_DETAILS=$(awk -v podid=${PODID} -v position=${PODID_POSITION} '{if($(NF-position) == podid){print}}' ${CRIO_PATH}/crictl_ps_-a 2>/dev/null | sed -e "s/About \([a-z]*\) \([a-z]*\) ago/About_\1_\2_ago/" -e "s/\([0-9]*\) \([a-z]*\) ago/\1_\2_ago/")
CONTAINER_IDS=($(echo "${CONTAINER_DETAILS}" |awk -v position=${PODID_POSITION} '{printf "%s,%s,%s ",$1,$(NF-position-2),$2}'))
}

#Retrieve container statistic
fct_container_statistic(){
  #Check if the container name is included in the crictl_stats data
  case ${CRICTL_STATS_TYPE} in
    "name")
      awk -v container_id=$1 '{if($1 == container_id){stats=$3"|"$4"|"$5"|"$6}}END{if (stats != ""){printf stats}else{printf "-|-|-|-"}}' ${CRIO_PATH}/crictl_stats 2>/dev/null
      ;;
    "other")
      awk -v container_id=$1 '{if($1 == container_id){stats=$2"|"$3"|"$4"|"$5}}END{if (stats != ""){printf stats}else{printf "-|-|-|-"}}' ${CRIO_PATH}/crictl_stats 2>/dev/null
      ;;
    *)
      echo | awk '{printf "-|-|-|-"}'
      ;;
  esac
}

#Retrieve POD list based on CGROUP
fct_cgroup(){
  if [[ ! -d ${PODPATH} ]]
  then
    echo -e "${redtext}ERR: The <$PODPATH> does not exist and is required for this option\nPlease check the content of the sosreport${resetcolor}\n" && fct_help && exit 9
  fi
  POD_IDS_LIST=($(jq -r --arg cgroup "${CGROUP}" '.? | select(.info.runtimeSpec.linux.cgroupsPath | test($cgroup)) | "\(.status.id[0:13]) "' $(file ${PODPATH}/crictl_inspectp_* | grep -E "JSON data" | cut -d':' -f1) 2>/dev/null))
  if [[ -z ${POD_IDS_LIST} ]]
  then
    CONTAINERID=$(jq -r --arg cgroup "$(echo ${CGROUP} | sed -e "s/crio-//")" '.? | select(.info.runtimeSpec.linux.cgroupsPath | test($cgroup)) | "\(.status.id[0:13])"' $(file ${CONTAINERPATH}/crictl_inspect* | grep -E "JSON data" | cut -d':' -f1) 2>/dev/null)
    fct_extract_from_container_id
  fi
}

#Check PROC files
fct_check_proc_files(){
  WARN=0
  if [[ ! -f ${PS_GROUP} ]]
  then
    echo -e "${yellowtext}WARN: File ${PS_GROUP} is missing${resetcolor}\n" | sed -e "s#[-0-9a-zA-Z._/]*\(sos_commands/process/[a-z\-_]*\)#\${SOSREPORT_PATH}/\1#g"
    WARN=$[WARN + 1]
  fi
  if [[ ! -f ${PSFAUXWWW} ]]
  then
    if [[ ! -f ${PSAUXWWWM} ]]
    then
      echo -e "${yellowtext}WARN: Files ${PSFAUXWWW} and ${PSAUXWWWM} are missing${resetcolor}\n" | sed -e "s#[-0-9a-zA-Z._/()]*\(sos_commands/process/[a-z\-_]*\)#\${SOSREPORT_PATH}/\1#g"
      WARN=$[WARN + 1]
    else
      echo -e "${yellowtext}INFO: File ${PSFAUXWWW} is missing, using file ${PSAUXWWWM} instead${resetcolor}\n" | sed -e "s#[-0-9a-zA-Z._/()]*\(sos_commands/process/[a-z\-_]*\)#\${SOSREPORT_PATH}/\1#g"
      PSFAUXWWW=${PSAUXWWWM}
    fi
  fi
  return ${WARN}
}

#Display the Container's Process details
fct_container_processes(){
  container_id=$1
  FILEPATH="${CONTAINERPATH}/crictl_inspect_${container_id}"
  FILENAME=$(ls -1 "${FILEPATH}"* 2>/dev/null)
  echo
  if [[ -z ${FILENAME} ]]
  then
    echo -e "${yellowtext}WARN: Unable to locate a inspect file in the matching the PATH: ${FILEPATH}*${resetcolor}\n"
  else
    Container_cgroup=$(jq -r '.info.runtimeSpec.linux.cgroupsPath' ${FILENAME} | sed -e "s/:crio:/\/crio-/")
    fct_check_proc_files
    WARN=$?
    if [[ ${WARN} == 0 ]]
    then
      echo "List of processes attached to the cgroup: ${Container_cgroup}"
      PROCESS_LIST="$(grep ${Container_cgroup} ${PS_GROUP} 2>/dev/null| awk '{printf "|^[a-zA-Z0-9+ ]*"$1"|^[a-zA-Z0-9+ ]*"$2}')"
      grep -E "^USER${PROCESS_LIST}" ${PSFAUXWWW} | less
    else
      echo -e "${redtext}ERR: Unable to retrieve the cgroup and/or PID as some files are missing.${resetcolor}\n"
    fi
  fi
}

# Retrieve Image Sizes to help troubleshoot diskPressure conditions - if possible based on correlating the overlay layers with the container names and ids
fct_image_size_overlay()
{
  IMAGE_JSON="[]"
  CONTAINER_LIST="[]"
  CONTAINER_FILE_LIST=$(file ${CONTAINERPATH}/crictl_inspect_* | grep -E "JSON data" | cut -d':' -f1)
  NBFILE=$(echo ${CONTAINER_FILE_LIST} | wc -w)
  Count=1
  for containerfile in ${CONTAINER_FILE_LIST}
  do
    if [[ ${DISPLAY_FILE_COUNT} == "true" ]]
    then
      printf "\rProcessing container file: %d/%d" $Count $NBFILE
      ((Count++))
    fi
    #The Image reference in latest version is available in .status.imageId, but in older version it is only available in .info.runtimeSpec.annotations."io.kubernetes.cri-o.ImageRef", so we need to check both
    CONTAINER_DETAILS=$(jq -r '{ "name": .status.metadata.name, "id": .status.id, "imageId": (if (.status.imageId == null) then .info.runtimeSpec.annotations."io.kubernetes.cri-o.ImageRef" else .status.imageId end), "namespace": .status.labels."io.kubernetes.pod.namespace", "podname": .status.labels."io.kubernetes.pod.name", "state": .status.state, "layerID": (.info.runtimeSpec.root.path | split("/") | .[6])}' ${containerfile})
    container_id=$(echo ${CONTAINER_DETAILS} | jq -r '.id' | cut -c1-13)
    case ${CRICTL_STATS_TYPE} in
      "name")
        DISK_SPACE=$(awk -v container_id=${container_id} '{if($1 == container_id){disk_value=substr($5,1,length($5)-2);disk_unit=substr($5,length($5)-1);if(disk_unit=="GB"){stats=(disk_value * 1024)} else if(disk_unit=="TB"){stats=(disk_value * 1024 * 1024)} else if((disk_unit=="kB") || (disk_unit=="KB")){stats=(disk_value / 1024)} else {stats=disk_value}}}END{if (stats != ""){printf stats}else{printf 0}}' ${CRIO_PATH}/crictl_stats 2>/dev/null)
        ;;
      "other")
        DISK_SPACE=$(awk -v container_id=${container_id} '{if($1 == container_id){disk_value=substr($4,1,length($4)-2);disk_unit=substr($4,length($4)-1);if(disk_unit=="GB"){stats=(disk_value * 1024)} else if(disk_unit=="TB"){stats=(disk_value * 1024 * 1024)} else if((disk_unit=="kB") || (disk_unit=="KB")){stats=(disk_value / 1024)} else {stats=disk_value}}}END{if (stats != ""){printf stats}else{printf 0}}' ${CRIO_PATH}/crictl_stats 2>/dev/null)
        ;;
      *)
        DISK_SPACE=0
        ;;
    esac
    CONTAINER_DETAILS=$(echo ${CONTAINER_DETAILS} | jq -r --arg disk_space "${DISK_SPACE}" '. + {"disk": $disk_space}')
    CONTAINER_LIST=$( echo ${CONTAINER_LIST} | jq -rc --argjson container_details "${CONTAINER_DETAILS}" '. + [ $container_details ]')
  done
  # Collect the shared layers across all images and count the number of images sharing each layer.
  SHARED_LAYERS=$(jq -rs '.[].info.imageSpec.rootfs."diff_ids"[]' $(file ${IMAGEPATH}/crictl_inspecti_* 2>/dev/null | grep -E "JSON data" | cut -d':' -f1) | sort | uniq -c | sort -n | grep -Ev "^ *1 sha256" | awk '{printf "%s+%d\n",$2,$1}')
  # Calculate the replicate space used by each shared layer
  SHARED_LAYER_JSON="[]"
  for sha256_layer in ${SHARED_LAYERS}
  do
    layer_id=$(echo ${sha256_layer} | cut -d'+' -f1)
    count=$(echo ${sha256_layer} | cut -d'+' -f2)
    if [[ -f ${OVERLAY_LAYERS_FILE} ]]
    then
      SHARED_LAYER_DETAILS=$(jq -r --arg layer ${layer_id} --arg count ${count} '.[] | select(."diff-digest" == $layer) | {"diff-digest",id,parent,"diff-size","count":$count}' ${OVERLAY_LAYERS_FILE})
    else
      SHARED_LAYER_DETAILS=$(jq -n --arg layer ${layer_id} --arg count ${count} '{"diff-digest": $layer, "id": null, "parent": null, "diff-size": null, "count": $count}')
    fi
    SHARED_LAYER_JSON=$(echo ${SHARED_LAYER_JSON} | jq -rc --argjson layer_details "${SHARED_LAYER_DETAILS}" '. + [ $layer_details ]')
  done
  if [[ -z ${IMAGEID} ]]
  then
    IMAGE_FILE_LIST=$(file ${IMAGEPATH}/crictl_inspecti_* 2>/dev/null | grep -E "JSON data" | cut -d':' -f1)
  else
    IMAGE_FILE_LIST=$(file ${IMAGEPATH}/crictl_inspecti_${IMAGEID}* 2>/dev/null | grep -E "JSON data" | cut -d':' -f1)
  fi
  if [[ ${DISPLAY_FILE_COUNT} == "true" ]]
  then
      echo
      NBFILE=$(echo ${IMAGE_FILE_LIST} | wc -w)
      Count=1
  fi
  # Create JSON data with the image details, the list of containers using this image and the layer details (size, shared or not)
  for imagefile in ${IMAGE_FILE_LIST}
  do
    if [[ ${DISPLAY_FILE_COUNT} == "true" ]]
    then
      printf "\rProcessing image file: %d/%d" $Count $NBFILE
      ((Count++))
    fi
    IMAGE_STATUS=$(jq -r '.status | {size,id,repoTags,repoDigests}' ${imagefile} 2>/dev/null)
    IMAGE_ID=$(echo ${IMAGE_STATUS} | jq -r '.id')
    SHA256_IMAGE_LAYERS=$(jq -r '.info.imageSpec.rootfs."diff_ids"[]' ${imagefile} 2>/dev/null)
    LAYER_JSON="[]"
    for sha256_layer in ${SHA256_IMAGE_LAYERS}
    do
      SHARED_LAYER_BOOL=$(echo ${SHARED_LAYER_JSON} | jq -r --arg layer "${sha256_layer}" '(.[] | select(."diff-digest" == $layer)| if (."diff-digest" == $layer) then true else false end) // false')
      if [[ -f ${OVERLAY_LAYERS_FILE} ]]
      then
        LAYER_DETAILS=$(jq -r --arg layer "${sha256_layer}" --arg shared ${SHARED_LAYER_BOOL} '(.[] | select(."diff-digest" == $layer) | {"diff-digest",id,parent,"diff-size","shared":$shared}) // {"diff-digest": $layer, "id": null, "parent": null, "diff-size": null, "shared": $shared}' ${OVERLAY_LAYERS_FILE})
      else
        LAYER_DETAILS=$(jq -n --arg layer "${sha256_layer}" --arg shared ${SHARED_LAYER_BOOL} '{"diff-digest": $layer, "id": null, "parent": null, "diff-size": null, "shared": $shared}')
      fi
      LAYER_JSON=$(echo ${LAYER_JSON} | jq -rc --argjson layer_details "${LAYER_DETAILS}" '. + [ $layer_details ]')
    done
    CONTAINER_MATCH=$(echo ${CONTAINER_LIST} | jq -r --arg imageid ${IMAGE_ID} '.[] | select(.imageId == $imageid) | {name, id: .id[0:13], layerID, state, namespace, podname, disk: (.disk | tonumber * 1000 | round /1000)}' | jq -s)
    # Creating a specific variable for each image to split the original huge variable.
    declare IMAGE_${IMAGE_ID}=$(echo "${IMAGE_STATUS}" | jq -rc --argjson containers "${CONTAINER_MATCH}" --argjson layer_json "${LAYER_JSON}" '[ {"status": ., "containers": $containers, "layers": $layer_json} ]')
    # Creating a global with limited data used only for global summary.
    IMAGE_JSON=$(echo ${IMAGE_JSON} | jq -rc --argjson image_status "${IMAGE_STATUS}" --argjson containers "${CONTAINER_MATCH}" --argjson layer_json "${LAYER_JSON}" '. + [ {"status": {"id": $image_status.id, "size": $image_status.size}, "containers": [ ($containers | .[].id) ], "layers": [ ($layer_json | .[] | {"diff-size", shared})] } ]')
  done
  echo
  clear

  if [[ -z ${IMAGEID} ]]
  then
    echo -e "##################################################"
    echo ${IMAGE_JSON} | jq -rc --argjson containers "${CONTAINER_LIST}" '(. | length) as $nbimages | ($containers | length) as $nbcontainers |"# Number of Images:|\($nbimages)\n# Number of Containers:|\($nbcontainers)"' | column -ts'|' | sed -e 's/[ \t]*$//'
    echo -e "##################################################"
    echo ${IMAGE_JSON} | jq -rc --argjson containers "${CONTAINER_LIST}" --argjson sharedlayerjson ${SHARED_LAYER_JSON} '([.[] | (.status.size // 0) | tonumber] | add * 100/1024/1024 | round/100) as $total | ([$sharedlayerjson | .[]? | ((."diff-size" // 0) | tonumber) * (((.count // 1) | tonumber) -1) ] | add * 100/1024/1024 | round/100) as $duplicshared | ([($containers | .[] | ((if (.disk == "null") then 0 else .disk end) // 0 | tonumber))] | add * 100 | round / 100) as $containersize|  "# TOTAL IMAGE SIZE:|\($total)|MB\n# DUPLICATE SHARED LAYERS SPACE:|\(if($duplicshared > 0) then "-\($duplicshared)|MB" else "Unknown" end)\n# CONTAINER LAYERS SPACE ON DISK:|\(if($containersize > 0) then "\($containersize)|MB" else "Unknown" end)\n# TOTAL USED SPACE ON DISK:|\(if(($duplicshared > 0) and ($containersize > 0)) then "\(($total - $duplicshared + $containersize) * 100 | round /100)|MB" else "Unknown" end)"' | column -ts'|' | sed -e 's/[ \t]*$//' -e "s/\(DUPLICATE SHARED LAYERS SPACE: *\)\([0-9.-]*\)/\1${purpletext}\2${resetcolor}/" -e "s/\(DUPLICATE SHARED LAYERS SPACE: *\)\([A-Za-z]*\)/\1${yellowtext}\2${resetcolor}/" -e "s/\(TOTAL IMAGE SIZE: *\)\([0-9.]*\)/\1${yellowtext}\2${resetcolor}/" -e "s/\(TOTAL USED SPACE ON DISK: *\)\([0-9.]*\)/\1${greentext}\2${resetcolor}/" -e "s/\(TOTAL USED SPACE ON DISK: *\)\([A-Za-z]*\)/\1${yellowtext}\2${resetcolor}/" -e "s/\(CONTAINER LAYERS SPACE ON DISK: *\)\([0-9.]*\)/\1${cyantext}\2${resetcolor}/" -e "s/\(CONTAINER LAYERS SPACE ON DISK: *\)\([A-Za-z]*\)/\1${yellowtext}\2${resetcolor}/"
    echo -e "##################################################"
  fi

  if [[ ${DISKPRESSURE} == "sum" ]] || [[ ${DISKPRESSURE} == "both" ]]
  then
    echo -e "\n############################################\n# IMAGES SUMMARY\n############################################\n"
    echo -e ${IMAGE_JSON} | jq -r '"Image| |Shared Layers| |Unique Layers| |Containers|\nID|Size|Size|Count|Size|Count|Count|",(sort_by(-(.status.size | tonumber)) | .[] | ((.status.size | tonumber) *100 /1024 /1024 | round/100) as $image_size | (.layers | map(select(.shared == "true"))) as $shared_layer | ([ $shared_layer | (.[]?."diff-size" // 0) | tonumber] | add | if(($shared_layer |length > 0) and ((. == 0) or (. == null))) then "Unknown" else if(. == null) then 0 else (. /1024 /1024 * 100 | round/100) end end) as $shared_size | (.layers | map(select(.shared == "false"))) as $unique_layer | ([ $unique_layer | (.[]?."diff-size" // 0) | tonumber] | add | if(($unique_layer |length > 0) and ((. == 0) or (. == null))) then "Unknown" else if(. == null) then 0 else (. /1024 /1024 * 100 | round/100) end end) as $unique_size | "\(.status.id)|\($image_size) MB|\($shared_size) MB|(\($shared_layer |length))|\($unique_size) MB|(\($unique_layer |length))|\(.containers | length)")' | column -ts'|' | sed -e 's/[ ]*$//' -e "s/\([0-9]\{4,10\}\.*[0-9]*\) MB/${redtext}\1${resetcolor} MB/g" -e "s/\([0-9]\{4,10\}\) MB/${redtext}\1${resetcolor} MB/g" -e "s/\([4-9][0-9]\{2\}\.[0-9]*\) MB/${yellowtext}\1${resetcolor} MB/g" -e "s/\([4-9][0-9]\{2\}\) MB/${yellowtext}\1${resetcolor} MB/g"
  fi
  if [[ ${DISKPRESSURE} == "layers" ]] || [[ ${DISKPRESSURE} == "both" ]]
  then
    echo -e "\n############################################\n# IMAGE LAYERS DETAILS\n############################################\n"

    for ID_ARRAY_SPLIT in $(echo ${IMAGE_JSON} | jq -r 'sort_by(-(.status.size | tonumber)) | .[].status.id')
    do
      ARRAY_INDEX="IMAGE_${ID_ARRAY_SPLIT}"
      # Retrieve the dedicated array for the current image.
      SPLIT_ARRAY=${!ARRAY_INDEX}
      echo ${SPLIT_ARRAY} | jq -r '.[] | .status | "Image ID: \(.id) - Repotag: \(.repoTags) - Repodigest: \(.repoDigests)"' | sed -e "s/\(Image ID:\)/${greentext}\1${resetcolor}/"
      echo ${SPLIT_ARRAY} | jq -r '.[] | ((.status.size | tonumber) *100 /1024 /1024 | round/100) as $image_size | (.layers | map(select(.shared == "true"))) as $shared_layer | (.layers | map(select(.shared == "false"))) as $unique_layer | " |-> Size: \($image_size) MB  / Shared layers: \($shared_layer |length) (\([ $shared_layer | (.[]?."diff-size" // 0) | tonumber] | add | if(($shared_layer |length > 0) and ((. == 0) or (. == null))) then "Unknown" else if(. == null) then 0 else (. /1024 /1024 * 100 | round/100) end end) MB) / Unique layers: \($unique_layer |length) (\([ $unique_layer | (.[]?."diff-size" // 0) | tonumber] | add | if(($unique_layer |length > 0) and ((. == 0) or (. == null))) then "Unknown" else if(. == null) then 0 else (. /1024 /1024 * 100 | round/100) end end) MB)"' | sed -e "s/\([0-9]\{4,10\}\.[0-9]*\) MB/${redtext}\1${resetcolor} MB/g" -e "s/\([4-9][0-9]\{2\}\.[0-9]*\) MB/${yellowtext}\1${resetcolor} MB/g" -e "s/Unknown/${yellowtext}Unknown${resetcolor}/g"
      echo -e " |-> ${purpletext}Layers${resetcolor} ($(echo ${SPLIT_ARRAY} | jq -r '.[].layers | length'))"
      echo ${SPLIT_ARRAY} | jq -r '" \\    Sha256#Layer ID#Layer Size#Parent#Shared",(.[].layers[]? | "  |-> \(."diff-digest")#\(.id)#\(if(."diff-size" != null) then "\(."diff-size"|tonumber /1024 /1024 * 100 | round/100) MB" else "Unknown" end)#\(.parent)#\(.shared)\n")' | column -ts'#' | sed -e 's/[ ]*$//' -e "s/true$/${yellowtext}true${resetcolor}/" -e "s/\([0-9]\{4,10\}\.[0-9]*\) MB/${redtext}\1${resetcolor} MB/g" -e "s/\([4-9][0-9]\{2\}\.[0-9]*\) MB/${yellowtext}\1${resetcolor} MB/g" -e "s/Unknown/${yellowtext}Unknown${resetcolor}/g"
      echo -e " /\n |-> ${cyantext}Containers${resetcolor} ($(echo ${SPLIT_ARRAY} | jq -r '.[].containers | length'))"
      if [[ $(echo ${SPLIT_ARRAY} | jq -r '.[].containers | length') != 0 ]]
      then
        echo ${SPLIT_ARRAY} | jq -r '" \\    Namespace#POD Name#Container Name#Container ID#Container Layer ID#Layer Used Space#State",(.[].containers | sort_by(.namespace,.podname,.name) | .[]? | "  |-> \(.namespace)#\(.podname)#\(.name)#\(.id)#\(.layerID)#\(.disk) MB#\(.state)")' | column -ts'#' | sed -e 's/[ ]*$//' | sed -e "s/CONTAINER_EXITED/${redtext}Exited${resetcolor}/" -e "s/CONTAINER_RUNNING/${greentext}Running${resetcolor}/" -e "s/\(CONTAINER_[A-Za-z0-9]*\)/${yellowtext}Running${resetcolor}/"
      fi
      echo -e "--------------------------------------------\n"
    done
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
# Max random number to check for update
MAX_RANDOM=10
# Source URLs & version time_gap
SOURCE_RAW_URL="https://raw.githubusercontent.com/vlours/sos4ocp/refs/heads/main/sos4ocp.sh"
SOURCE_URL="https://github.com/vlours/sos4ocp/"
# Display the number of processed files during the image size calculation (can be set to "false" to disable it)
DISPLAY_FILE_COUNT=${DISPLAY_FILE_COUNT:-"true"}

# Getops
if [[ $# != 0 ]]
then
  if [[ $1 == "-" ]] || [[ $1 =~ ^[a-zA-Z0-9] ]]
  then
    echo -e "Invalid option: ${1}\n"
    fct_help && exit 1
  fi
  OPTNUM=0
  while getopts :i:I:p:c:D:g:m:n:o:P:u:s:S:hv arg; do
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
      D)
        DISKPRESSURE=${OPTARG}
        case ${DISKPRESSURE} in
          sum|both|layers)
            ;;
          *)
            echo -e "${redtext}Err: invalid value '${DISKPRESSURE}' for the diskPressure option${resetcolor}"
            fct_help && exit 1
            ;;
        esac
        if [[ -z ${IMAGEID} ]]
        then
          OPTNUM=$[OPTNUM + 1]
        fi
        ;;
      g)
        CGROUP=${OPTARG}
        OPTNUM=$[OPTNUM + 1]
        PODFILTER="CGROUP"
        ;;
      m)
        IMAGEID=${OPTARG}
        PODFILTER="IMAGE"
        if [[ -z ${DISKPRESSURE} ]]
        then
          OPTNUM=$[OPTNUM + 1]
        fi
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
      P)
        PROC_PID=${OPTARG}
        OPTNUM=$[OPTNUM + 1]
        PODFILTER="PROCPID"
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
            echo -e "${redtext}Err: invalid sorting key '${SORT_KEY}' for the container statistic${resetcolor}"
            fct_help && exit 1
            ;;
        esac
        PODFILTER="STATISTIC"
        OPTNUM=$[OPTNUM + 1]
        ;;
      h)
        fct_help && exit 0
        ;;
      v)
        MAX_RANDOM=1
        fct_version && exit 0
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
  fct_help && exit 2
fi
SOSREPORT_PATH=${SOSREPORT_PATH:-.}
PODNAME=${PODNAME:-"null"}
PODID=${PODID:-"null"}
CONTAINERNAME=${CONTAINERNAME:-"null"}
CGROUP=${CGROUP:-"null"}
NAMESPACE=${NAMESPACE:-"null"}

# Check if the SOSREPORT_PATH is valid and set CRIO_PATH
if [[ ! -d ${SOSREPORT_PATH}/sos_commands/crio ]]
then
  if [[ -d "$(ls -1d ${SOSREPORT_PATH}/*sosreport* 2>${STD_ERR}| head -1)/sos_commands/crio" ]]
  then
    SOSREPORT_PATH=$(ls -1d ${SOSREPORT_PATH}/*sosreport* 2>${STD_ERR}| head -1)
  else
    echo -e "${redtext}Err: Unable to find the 'crio' folder in the SOSREPORT PATH. Invalid SOSREPORT PATH: ${SOSREPORT_PATH}${resetcolor}"
    fct_help && exit 5
  fi
fi
CRIO_PATH=${SOSREPORT_PATH}/sos_commands/crio

# Check and Set the LOGPATH, CONTAINERPATH & PODPATH variables
LOGPATH=${LOGPATH:-$(dirname $(find  ${CRIO_PATH}/ -name "crictl_logs_*")  2>/dev/null | sort -u)}
if [[ -z ${LOGPATH} ]]
then
  echo -e "${yellowtext}WARN: Unable to find any crictl_logs_\* file in the crio folder: ${CRIO_PATH}\nSetting the variable \$LOGPATH to the default: \${CRIO_PATH}/logs ${resetcolor}\n"
  LOGPATH=${CRIO_PATH}/logs
fi
CONTAINERPATH=${CONTAINERPATH:-$(dirname $(find  ${CRIO_PATH}/ -name "crictl_inspect_*")  2>/dev/null | sort -u)}
if [[ -z ${CONTAINERPATH} ]]
then
  echo -e "${yellowtext}WARN: Unable to find any crictl_inspect_\* file in the crio folder: ${CRIO_PATH}\nSetting the variable \$CONTAINERPATH to the default: \${CRIO_PATH}/containers ${resetcolor}\n"
  CONTAINERPATH=${CRIO_PATH}/containers
fi
PODPATH=${PODPATH:-$(dirname $(find  ${CRIO_PATH}/ -name "crictl_inspectp*")  2>/dev/null | sort -u)}
if [[ -z ${PODPATH} ]]
then
  echo -e "${yellowtext}WARN: Unable to find any crictl_inspectp_\* file in the crio folder: ${CRIO_PATH}\nSetting the variable \$PODPATH to the default: \${CRIO_PATH}/pods ${resetcolor}\n"
  PODPATH=${CRIO_PATH}/pods
fi

if [[ ! -f ${CRIO_PATH}/crictl_pods ]] || [[ ! -f ${CRIO_PATH}/crictl_ps_-a ]]
then
  if [[ -f ${CRIO_PATH}/systemctl_status_crio ]]
  then
    echo -e "${redtext}Err: The crictl output 'crictl_pods' and/or 'crictl_ps_-a' are missing. Please check the logs from ${CRIO_PATH}/systemctl_status_crio\n${resetcolor}"
  else
    echo -e "${redtext}Err: The crictl output 'crictl_pods' and/or 'crictl_ps_-a' and the 'systemctl_status_crio' are missing. Please check the content of the sosreport\n${resetcolor}"
  fi
  fct_help && exit 6
fi
# Other SOSREPORT File references
PSFAUXWWW="${SOSREPORT_PATH}/sos_commands/process/ps_auxfwww"
PSAUXWWWM="${SOSREPORT_PATH}/sos_commands/process/ps_auxwwwm"
PS_GROUP="${SOSREPORT_PATH}/sos_commands/process/ps_axo_pid_ppid_user_group_lwp_nlwp_start_time_comm_cgroup"

# Check the type of crictl_stats files here as used in all options.
if [[ -f ${CRIO_PATH}/crictl_stats ]] && [[ -z $(grep "level=fatal msg=" ${CRIO_PATH}/crictl_stats 2>/dev/null) ]]
then
  if [[ $(awk 'BEGIN{namepresence="false"}{if($2 == "NAME"){namepresence="true"}}END{print namepresence}' ${CRIO_PATH}/crictl_stats) == "true" ]]
  then
    CRICTL_STATS_TYPE=name
  else
    CRICTL_STATS_TYPE=other
  fi
else
  echo -e "${yellowtext}WARN: The file crictl_stats is missing or invalid. Unable to provide the PODs' statistics${resetcolor}\n"
  CRICTL_STATS_TYPE=none
fi

if [[ ! -z ${DISKPRESSURE} ]]
then
  OVERLAY_LAYERS_FILE=${SOSREPORT_PATH}/var/lib/containers/storage/overlay-layers/layers.json
  IMAGEPATH=${IMAGEPATH:-$(dirname $(find  ${CRIO_PATH}/ -name "crictl_inspecti_*")  2>/dev/null | sort -u)}
  if [[ -z ${IMAGEPATH} ]]
  then
    echo -e "${redtext}ERR: Unable to find any crictl_inspecti_\* file in the crio folder: ${IMAGEPATH}\nPlease check the content of the sosreport${resetcolor}\n" && exit 8
  fi
  if [[ -z ${CONTAINERPATH} ]]
  then
    echo -e "${yellowtext}WARN: container inspect files are missing. Unable to correlate the image size with the container name and ids${resetcolor}\n"
  fi
  if [[ -f ${OVERLAY_LAYERS_FILE} ]]
  then
    fct_image_size_overlay
  else
    echo -e "${yellowtext}WARN: Unable to find the overlay layers file in the sosreport (<SOSREPORT_PATH>/var/lib/containers/storage/overlay-layers/layers.json).\nThe image size will be calculated based on the crictl_inspecti_* files only, without correlating with the shared layers sizes.${resetcolor}\n"
    fct_image_size_overlay
    echo -e "\n${yellowtext}WARN: Unable to find the overlay layers file in the sosreport (<SOSREPORT_PATH>/var/lib/containers/storage/overlay-layers/layers.json).\nThe image size will be calculated based on the crictl_inspecti_* files only, without correlating with the shared layers sizes.${resetcolor}\n"
  fi
  exit 0
fi

clear

#Check the crictl_ps_-a file to be able to correlate the POD ID based on the collected data in the crictl_ps_-a file.
PODID_POSITION=$(head -1 ${CRIO_PATH}/crictl_ps_-a 2>/dev/null | awk '{if($NF == "NAMESPACE"){print "2"}else if($NF == "POD"){print "1"}else{print "0"}}')

#Checking the number of options provided and set the POD_LIST variable with the corresponding POD IDs based on the provided option or with all the PODs if no option is provided
if [[ ${OPTNUM} == 0 ]]
then
  POD_LIST=($(awk '{if(($1 != "POD") && ($1 !~ "^time=")){printf "%s,%s,%s,%s\n",$1,$(NF-3),$(NF-2),$(NF-4)}}' ${CRIO_PATH}/crictl_pods 2>/dev/null | sort -r -k 4 -k3 -t',' | awk '{printf "%s ",$0}'))
  fct_pod_list_menu
else
  case ${PODFILTER} in
    "NAME")
      POD_IDS_LIST=($(awk -v podname=${PODNAME} '{if($(NF-3) == podname){print $1}}' ${CRIO_PATH}/crictl_pods 2>/dev/null | sort -u | awk '{printf "%s ",$0}'))
      echo -e "List of PODs including the name: ${PODNAME}\n"
      PODNAME="null"
      ;;
    "ID")
      POD_IDS_LIST=($(awk -v podid=${PODID} '{if($1 == podid){print $1}}' ${CRIO_PATH}/crictl_pods 2>/dev/null | sort -u | awk '{printf "%s ",$0}'))
      echo -e "List of PODs including the ID: ${PODID}\n"
      PODID="null"
      ;;
    "CONTAINER")
      POD_IDS_LIST=($(awk -v containername=${CONTAINERNAME} -v position=${PODID_POSITION} '{if($(NF-position-2) == containername){print $(NF-position)}}' ${CRIO_PATH}/crictl_ps_-a 2>/dev/null | sort -u  | awk '{printf "%s ",$0}'))
      echo -e "List of PODs including the container: ${CONTAINERNAME}\n"
      ;;
    "CONTAINERID")
      fct_extract_from_container_id
      echo -e "List of PODs including the container ID: ${CONTAINERID}\n"
      ;;
    "CGROUP")
      fct_cgroup
      echo -e "List of PODs including the cgroup: ${CGROUP}\n"
      ;;
    "IMAGE")
      POD_IDS_LIST=($(awk -v imageid=${IMAGEID} -v position=${PODID_POSITION} '{if($(2) == imageid){print $(NF-position)}}' ${CRIO_PATH}/crictl_ps_-a 2>/dev/null | sort -u | awk '{printf "%s ",$0}'))
      echo -e "List of PODs including the image ID: ${IMAGEID}\n"
      ;;
    "NAMESPACE")
      POD_IDS_LIST=($(awk -v pod_namespace=${NAMESPACE} '{if($(NF-2) == pod_namespace){printf "%s ",$1}}' ${CRIO_PATH}/crictl_pods 2>/dev/null))
      echo -e "List of PODs from the namespce: ${NAMESPACE}\n"
      ;;
    "STATISTIC")
      if [[ -f ${CRIO_PATH}/crictl_stats ]] && [[ -z $(grep "level=fatal msg=" ${CRIO_PATH}/crictl_stats 2>/dev/null) ]]
      then
        POD_DETAILS=$(grep -Ev "^POD" ${CRIO_PATH}/crictl_pods)
        CONTAINER_DETAILS=$(awk '{if($1 != "CONTAINER"){print}}' ${CRIO_PATH}/crictl_ps_-a 2>/dev/null | sed -e "s/About \([a-z]*\) \([a-z]*\) ago/About_\1_\2_ago/" -e "s/\([0-9]*\) \([a-z]*\) ago/\1_\2_ago/")
        CONTAINER_IDS=($(echo "${CONTAINER_DETAILS}" |awk -v position=${PODID_POSITION} '{if($(NF-position+1) != ""){podname=$(NF-position+1)}else{podname="-"} printf "%s|%s|%s|%s|%s|%s|%s ",$(NF-position),podname,$1,$5,$4,$3,$6}'))
      else
        if [[ ! -f ${CRIO_PATH}/crictl_stats ]]
        then
          echo -e "${redtext}ERR: Unable to find the stats file: ${CRIO_PATH}/crictl_stats\n${resetcolor}\n" && fct_help && exit 7
        else
          echo -e "${redtext}ERR: Fatal error detected in the stats file: ${CRIO_PATH}/crictl_stats\n${resetcolor}\n" && fct_help && exit 8
        fi
      fi
      ;;
    "OVERLAY")
      if [[ ! -d ${PODPATH} ]]
      then
        echo -e "${redtext}ERR: The <$PODPATH> does not exist and is required for this option\nPlease check the content of the sosreport${resetcolor}\n" && fct_help && exit 9
      fi
      POD_IDS_LIST=($(jq -r --arg overlay "${OVERLAY}" '.? | select(.info.runtimeSpec.root.path | test($overlay)) | "\(.status.id[0:13]) "' $(file ${PODPATH}/crictl_inspectp_* | grep -E "JSON data" | cut -d':' -f1) 2>/dev/null))
      if [[ -z ${POD_IDS_LIST} ]]
      then
        CONTAINERID=$(jq -r --arg overlay "$(echo ${OVERLAY} | sed -e "s/crio-//")" '.? | select(.info.runtimeSpec.root.path | test($overlay)) | "\(.status.id[0:13])"' $(file ${CONTAINERPATH}/crictl_inspect* | grep -E "JSON data" | cut -d':' -f1) 2>/dev/null)
        fct_extract_from_container_id
      fi
      echo -e "List of PODs including the overlay: ${OVERLAY}\n"
      ;;
    "PROCPID")
      fct_check_proc_files
      WARN=$?
      if [[ ${WARN} == 0 ]]
      then
        CGROUP="$(awk -v  procid=${PROC_PID} '{if($1 == procid){print}}' ${PS_GROUP} 2>/dev/null | sed -e "s/.*crio-[a-z-]*\([0-9a-zA-Z_]*\).scope.*/\1/")"
        if [[ ! -z ${CGROUP} ]]
        then
          fct_cgroup
        fi
      else
        echo -e "${redtext}ERR: Unable to retrieve the Process ID details as the process files are missing.${resetcolor}\n"
      fi
      echo -e "List of PODs including the PROC_PID: ${PROC_PID}\n"
      ;;
    "PODUID")
      if [[ ! -d ${PODPATH} ]]
      then
        echo -e "${redtext}ERR: The <$PODPATH> does not exist and is required for this option\nPlease check the content of the sosreport${resetcolor}\n" && fct_help && exit 9
      fi
      POD_IDS_LIST=($(jq -r --arg poduid "${PODUID}" '.? | select(.status.metadata.uid == $poduid) | "\(.status.id[0:13]) "' $(file ${PODPATH}/crictl_inspectp_* | grep -E "JSON data" | cut -d':' -f1) 2>/dev/null))
      echo -e "List of PODs including the POD_UID: ${PODUID}\n"
      ;;
  esac
fi

if [[ ${PODFILTER} == "STATISTIC" ]]
then
  NUM=0
  OPTION_NUM=$(echo ${#CONTAINER_IDS[@]})
  CONTAINERS_STAT_LIST=$(while [[ ${NUM} -lt ${OPTION_NUM} ]]
  do
    CONTAINER_ID=$(echo ${CONTAINER_IDS[${NUM}]} | cut -d'|' -f3)
    echo "$(echo ${CONTAINER_IDS[${NUM}]} | cut -d',' -f1)|$(fct_container_statistic ${CONTAINER_ID})" | sed -e "s/About_\([a-z]*\)_\([a-z]*\)_ago/About \1 \2 ago/" -e "s/\([0-9]*\)_\([a-z]*\)_ago/\1 \2 ago/"
    NUM=$[NUM+1]
  done | sort -${SORTFILTER}r -t'|' -k${SORT_VALUE})
  SUM_STATS=$(awk 'BEGIN{sum_cpu=0;sum_mem=0;sum_disk=0;sum_inode=0} {sum_cpu+=$3;mem_value=substr($4,1,length($4)-1);mem_unit=substr($4,length($4)-1);if(mem_unit=="GB"){sum_mem+=(mem_value * 1024)} else if(mem_unit=="TB"){sum_mem+=(mem_value * 1024 * 1024)} else if((mem_unit=="kB")||(mem_unit=="KB")){sum_mem+=(mem_value / 1024)} else {sum_mem+=mem_value};disk_value=substr($5,1,length($5)-2);disk_unit=substr($5,length($5)-1);if(disk_unit=="GB"){sum_disk+=(disk_value * 1024)} else if(disk_unit=="TB"){sum_disk+=(disk_value * 1024 * 1024)} else if((disk_unit=="kB") || (disk_unit=="KB")){sum_disk+=(disk_value / 1024)} else {sum_disk+=disk_value};sum_inode+=$NF} END{print sum_cpu"|"sum_mem" MB|"sum_disk" MB|"sum_inode}' ${CRIO_PATH}/crictl_stats)
  echo -e " | | | | | |TOTAL|${SUM_STATS}\n | | | | | |-------|-------------|---------|----------|------|\nPOD ID|POD NAME|CONTAINER ID|CONTAINER NAME|STATE|CREATED|ATTEMPT|CPU USAGE (%)|MEM USAGE|DISK USAGE|INODES|\n------|---------|------------|--------------|-----|-------|-------|-------------|---------|----------|------|\n${CONTAINERS_STAT_LIST}" | column -t -s'|'
else
  if [[ ${#POD_IDS_LIST[@]} == 1 ]]
  then
    PODID=${POD_IDS_LIST[0]}
  else
    if [[ ${#POD_IDS_LIST[@]} -ge 2 ]]
    then
      POD_LIST=($(awk '{if(($1 != "POD") && ($1 !~ "^time=")){printf "%s,%s,%s,%s\n",$1,$(NF-3),$(NF-2),$(NF-4)}}' ${CRIO_PATH}/crictl_pods 2>/dev/null | sort -r -k 4 -k3 -t',' | awk -F',' -v pod_ids="$(echo "${POD_IDS_LIST[@]}")" 'BEGIN{split(pod_ids,pod_array," ")}{for(ID in pod_array){if($1 == pod_array[ID]){printf "%s ",$0}}}'))
      fct_pod_list_menu
    fi
  fi
  # Trunking the PODID to 13 characters
  PODID=$(echo ${PODID}  | cut -c1-13)

  # Collect the POD Details & set the missing value
  POD_HEADER=$(awk '($1 == "POD"){print}' ${CRIO_PATH}/crictl_pods 2>/dev/null | sed -e "s/POD ID/POD_ID/")
  POD_DETAILS=${POD_DETAILS:-$(awk -v podid=${PODID} '{if(($1 == podid) || ($(NF-3) == podname)){print} }' ${CRIO_PATH}/crictl_pods 2>/dev/null | sed -e "s/About \([a-z]*\) \([a-z]*\) ago/About_\1_\2_ago/" -e "s/\([0-9]*\) \([a-z]*\) ago/\1_\2_ago/")}
  if [[ -z "${POD_DETAILS}" ]]
  then
    echo -e "Unable to find a POD from the specified parameter\n" && fct_help && exit 10
  fi
  PODID=$(echo "${POD_DETAILS}" | awk '{print $1}')
  PODNAME=$(echo "${POD_DETAILS}" | awk '{print $(NF-3)}')
  # Collect the Container(s) details and create an Array with the IDs
  fct_container_details
  # Create the List of option  for the Menu
  CONTAINER_HEADER=$(awk '($1 == "CONTAINER"){print}' ${CRIO_PATH}/crictl_ps_-a | sed -e "s/POD ID/POD_ID/")
  LIST_OPTION=("Inspect POD:|${PODNAME}|(${PODID}),fct_inspect "pod" ${PODID}")
  for CONTAINER_INFO in ${CONTAINER_IDS[*]}
  do
    CONTAINER_ID=$(echo ${CONTAINER_INFO} | cut -d',' -f1)
    CONTAINER_NAME=$(echo ${CONTAINER_INFO} | cut -d',' -f2)
    CONTAINER_IMAGE=$(echo ${CONTAINER_INFO} | cut -d',' -f3)
    FILEPATH="${CONTAINERPATH}/crictl_inspect_${CONTAINER_ID}"
    FILENAME=$(ls -1 ${FILEPATH}* 2>/dev/null)
    if [[ -f ${FILENAME} ]]
    then
      ATTEMPTS=$(jq -r '.status.metadata.attempt' ${FILENAME} 2>/dev/null)
    else
      ATTEMPTS=$(awk -v containerid=${CONTAINER_ID} '{if($1 == containerid){printf "%s",$(NF-2)}}' ${CRIO_PATH}/crictl_ps_-a 2>/dev/null)
    fi
    if ([[ ! -z ${CONTAINERID} ]] && [[ ${CONTAINERID} == ${CONTAINER_ID} ]]) || ([[ ! -z ${CONTAINERNAME} ]] && [[ ${CONTAINERNAME} == ${CONTAINER_NAME} ]]) || ([[ ! -z ${IMAGEID} ]] && [[ ${IMAGEID} == ${CONTAINER_IMAGE} ]])
    then
      LIST_OPTION+=("Inspect Container:|${CONTAINER_NAME}|(${CONTAINER_ID})|${ATTEMPTS}|$(fct_container_statistic ${CONTAINER_ID})|<<<<< Matching Filter,fct_inspect "container" ${CONTAINER_ID}")
    else
      LIST_OPTION+=("Inspect Container:|${CONTAINER_NAME}|(${CONTAINER_ID})|${ATTEMPTS}|$(fct_container_statistic ${CONTAINER_ID}),fct_inspect "container" ${CONTAINER_ID}")
    fi
    LIST_OPTION+=("Display Container log:|${CONTAINER_NAME}|(${CONTAINER_ID}),fct_inspect "log" ${CONTAINER_ID}")
    LIST_OPTION+=("Display Container proc:|${CONTAINER_NAME}|(${CONTAINER_ID}),fct_container_processes ${CONTAINER_ID}")
  done
  OPTION_NUM=$(echo ${#LIST_OPTION[@]})
  fct_display_menu
fi

echo "" && fct_version
exit 0
