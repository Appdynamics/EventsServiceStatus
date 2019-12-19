#!/bin/bash 
# 
# Monitors Disks on Linux 
# 
# $Id: disk-stat.sh 3.20 2017-06-02 15:05:40 cmayer $
# 
# using only: iostat, awk
# 
# Copyright 2016 AppDynamics, Inc 
# 
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at 
# 
# http://www.apache.org/licenses/LICENSE-2.0 
# 
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
# See the License for the specific language governing permissions and 
# limitations under the License. 
#
CURR_PATH=`pwd`
PATH=$PATH:/bin:/usr/sbin:/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:$CURR_PATH

COUNTER=0
LOG_LINE=$(date +%F-%T)
LOG_LINE+="[INFO]: Starting monitoring extension...."

echo $LOG_LINE >> es_monitor.log

#SPACE SEPARATED LIST OF DISKS TO BE MONITORED THIS SHOULD MATHC THE DISKS ALREADY BEING MONITORED BY THE DiskMonitor extension
CLUSTER_URL="l02913papp0"
CLUSTER_PORT=9081

while [ $COUNTER -ge 0 ]; do
	#connecting to the cluster
	CLUSTER_HTTP_STATUS=$( curl http://$CLUSTER_URL:$CLUSTER_PORT/healthcheck?pretty=true -s -o es_status.json -w "%{http_code}")
	CLUSTER_STATE=$(curl http://$CLUSTER_URL:$CLUSTER_PORT/healthcheck?pretty=true |jq '."events-service-api-store / Connection to ElasticSearch: clusterName=[appdynamics-events-service-cluster]".message'| sed 's/\"clusterState=\[//g' | sed s/\],//g | awk '{print $1}')

	if [ $CLUSTER_STATE == "HEALTHY" ]; then
		CLUSTER_INTEGER_STATE=1
	else
		if [ $CLUSTER_STATE == "DEGRADED" ]; then
			CLUSTER_INTEGER_STATE=2
		else
			CLUSTER_INTEGER_STATE=3
		fi
	fi
	echo "name=Custom Metrics|ES Cluster|cluster state,aggregator=AVERAGE,value=$CLUSTER_INTEGER_STATE"
	echo "name=Custom Metrics|ES Cluster|cluster http status,aggregator=AVERAGE,value=$CLUSTER_HTTP_STATUS"
	sleep 10
done
#iostat -xk 1 | awk ' 
#/Device:/ { state ++; next }
#( NF == 12 && state >= 2) { 
#   state=2;
#   agg="AVERAGE"; 
#   dev = $1; 
#   printf("name=Hardware Resources|Disk|%s|avg req size (s),aggregator=%s,value=%d\n", dev, agg, $8); 
#   printf("name=Hardware Resources|Disk|%s|avg queue length,aggregator=%s,value=%d\n", dev, agg, $9); 
#   printf("name=Hardware Resources|Disk|%s|avg wait (ms),aggregator=%s,value=%d\n", dev, agg, $10); 
#   printf("name=Hardware Resources|Disk|%s|avg svctime (ms),aggregator=%s,value=%d\n", dev, agg, $11); 
#   printf("name=Hardware Resources|Disk|%s|utilization (ms),aggregator=%s,value=%d\n", dev, agg, $12); 
#   next
#} 
#( NF == 14 && state >= 2) { 
#   state=2;
#   agg="AVERAGE"; 
#   dev = $1; 
#   printf("name=Hardware Resources|Disk|%s|reads per sec,aggregator=%s,value=%d\n", dev, agg, $4); 
#   printf("name=Hardware Resources|Disk|%s|writes per sec,aggregator=%s,value=%d\n", dev, agg, $5); 
#   printf("name=Hardware Resources|Disk|%s|reads (kb/s),aggregator=%s,value=%d\n", dev, agg, $6); 
#   printf("name=Hardware Resources|Disk|%s|writes (kb/s),aggregator=%s,value=%d\n", dev, agg, $7); 
#   printf("name=Hardware Resources|Disk|%s|avg req size (s),aggregator=%s,value=%d\n", dev, agg, $8); 
#   printf("name=Hardware Resources|Disk|%s|avg queue length,aggregator=%s,value=%d\n", dev, agg, $9); 
#   printf("name=Hardware Resources|Disk|%s|avg wait (ms),aggregator=%s,value=%d\n", dev, agg, $10); 
#   printf("name=Hardware Resources|Disk|%s|avg read await (ms),aggregator=%s,value=%d\n", dev, agg, $11); 
#   printf("name=Hardware Resources|Disk|%s|avg write await (ms),aggregator=%s,value=%d\n", dev, agg, $12); 
#   next
#} '
