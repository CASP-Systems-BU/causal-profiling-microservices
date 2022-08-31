#!/bin/bash
. docker-conf.config
read -p "Script mode: 1.TCP Dump 2.Jaeger 3.No Jaeger 4. Mock benchmark" input_choice
echo $input_choice
thread_count=$1
connections=$2
benchmark_duration=$3
total_rps=$4
echo "Running benchmark for script mode ${input_choice} for thread count: ${thread_count} connections: ${connections} requests per second: ${total_rps} duration: ${benchmark_duration}"
if [[ $input_choice -eq 4 ]]
then
  echo "Running workload...."
  ubuntuclient=$(oc -n social-network get pod | grep ubuntu-client- | cut -f 1 -d " ")
  oc exec "$ubuntuclient" -- bash -c "cd /root/DeathStarBench/socialNetwork/wrk2 && \
        ./wrk -D exp -t ${thread_count} -c ${connections} -d ${benchmark_duration}s -R ${total_rps} -L -P -s ./scripts/social-network/read-user-timeline.lua http://nginx-thrift.social-network.svc.cluster.local:8080/wrk2-api/user-timeline/read" > benchmark-exp-logs/experiment-${input_choice}-${total_rps}.log
  sleep 1m
  exit 0
fi
#read -p "Start from scratch? Y/N" scratch_choice
scratch_choice="y"
echo "Please make sure you have logged in to your kubernetes cluster....."
#Deploy service if doing from scratch
if [[ $scratch_choice == [yY] ]]
then
  oc delete all --all --namespace social-network
  sleep 60
  if [[ $input_choice -eq 1 ]] || [[ $input_choice -eq 3 ]]
  then
    echo "Disabling jaeger....."
    cp ../nginx-thrift-config/jaeger-config-disabled.json ../nginx-thrift-config/jaeger-config.json
    cp ../config/jaeger-config-disabled.yml ../config/jaeger-config.yml
  fi
  if [[ $input_choice -eq 2 ]]
  then
    echo "Enabling jaeger....."
    cp ../nginx-thrift-config/jaeger-config-enabled.json ../nginx-thrift-config/jaeger-config.json
    cp ../config/jaeger-config-enabled.yml ../config/jaeger-config.yml
  fi
  sh configmaps/update-jaeger-configmap.sh
  oc create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username="$docker_username" --docker-password="$docker_password" --docker-email="$docker_email"
  oc get secret regcred --output=yaml
  sh deploy-all-services-and-configurations.sh
  total_pods=$(oc get pods  -n social-network --output name | wc -l)
  while [ $(oc get pods  -n social-network --output name --field-selector=status.phase=Running | wc -l) -ne "$total_pods" ]; do
     sleep 60
  done
  sleep 60
  ubuntuclient=$(oc -n social-network get pod | grep ubuntu-client- | cut -f 1 -d " ")
  oc cp "/Users/acemaster/Documents/BU Code/RA/DeathStarBench" social-network/"${ubuntuclient}":/root
  oc exec "$ubuntuclient" -- bash -c "cd /root/DeathStarBench/socialNetwork/wrk2 && make clean && make"
  sleep 120
fi
ALL_PODS=$(oc get pod -n social-network --field-selector=status.phase=Running -o custom-columns=name:metadata.name --no-headers)
# Starting script in TCP Dump mode
if [[ $input_choice -eq 1 ]]
then
  rm -rf tcpData
  mkdir tcpData
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
     sleep 60
  done
  echo "Running workload...."
  ubuntuclient=$(oc -n social-network get pod | grep ubuntu-client- | cut -f 1 -d " ")
  oc exec "$ubuntuclient" -- bash -c "cd /root/DeathStarBench/socialNetwork/wrk2 && \
        ./wrk -D exp -t ${thread_count} -c ${connections} -d ${benchmark_duration}s -R ${total_rps} -L -P -s ./scripts/social-network/read-user-timeline.lua http://nginx-thrift.social-network.svc.cluster.local:8080/wrk2-api/user-timeline/read" > benchmark-exp-logs/experiment-${input_choice}-${total_rps}.log
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
#  python read-pcap-file.py
fi
# Starting script in Jaeger/No Jaeger mode mode
if [[ $input_choice -eq 2 ]] || [[ $input_choice -eq 3 ]]
then
  echo "Running workload...."
  ubuntuclient=$(oc -n social-network get pod | grep ubuntu-client- | cut -f 1 -d " ")
  oc exec "$ubuntuclient" -- bash -c "cd /root/DeathStarBench/socialNetwork/wrk2 && \
        ./wrk -D exp -t ${thread_count} -c ${connections} -d ${benchmark_duration}s -R ${total_rps} -L -P -s ./scripts/social-network/read-user-timeline.lua http://nginx-thrift.social-network.svc.cluster.local:8080/wrk2-api/user-timeline/read" > benchmark-exp-logs/experiment-${input_choice}-${total_rps}.log
  sleep 1m
fi
