#!/usr/bin/env bash

RESOURCE_MANAGER_STATUS=$(curl --fail --silent "http://localhost:8088/ws/v1/cluster/info" | jq '.clusterInfo.state' | tr -d '"')
NOT_IN_SAFE_MODE=$(hdfs dfsadmin -report | grep "Safe mode is ON" | wc -l)
if [ ${RESOURCE_MANAGER_STATUS} == "STARTED" -a ${NOT_IN_SAFE_MODE} ]; then
 exit 0
else
 exit 1
fi



