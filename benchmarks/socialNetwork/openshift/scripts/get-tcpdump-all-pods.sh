#!/bin/bash

rm -rf tcpData
mkdir tcpData
ALL_PODS=$(oc get pod -n social-network --field-selector=status.phase=Running -o custom-columns=name:metadata.name --no-headers)
echo "Starting tcpdump for all pods ....."
pid_arr=()
for pod in $ALL_PODS; do
  echo "Starting ksniff on pod: $pod"
  oc sniff -p "$pod" -n social-network -o tcpData/output-"$pod".pcap & pid=$!
  pid_arr+=("$pid")
done
sleep 60
echo "Wait for all ksniff pods to be up...."
total_pods=$(oc get pods  -n social-network --output name | wc -l)
while [ $(oc get pods  -n social-network --output name --field-selector=status.phase=Running | wc -l) -ne "$total_pods" ]; do
   sleep 5
done
echo "Running workload...."
ubuntuclient=$(oc -n social-network get pod | grep ubuntu-client- | cut -f 1 -d " ")
oc exec "$ubuntuclient" -- bash -c "cd /root/DeathStarBench/socialNetwork/wrk2 && \
      ./wrk -D exp -t 2 -c 10 -d 30s -L -s ./scripts/social-network/read-user-timeline.lua http://nginx-thrift.social-network.svc.cluster.local:8080/wrk2-api/user-timeline/read -R 20"
sleep 1m
echo "Killing all knsiff processes...."
for value in "${pid_arr[@]}"
do
     kill -9 "$value"
done
echo "Deleting all ksniff pods...."
oc delete pods -l app=ksniff
sleep 30
mergecap -w tcpData/final-output.pcap tcpData/*.pcap
python read-pcap-file.py
