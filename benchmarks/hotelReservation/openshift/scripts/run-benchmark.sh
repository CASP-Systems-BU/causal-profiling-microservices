#!/bin/bash
. docker-conf.config

set_benchmark_file_name() {
  if [[ $input_choice -eq 1 ]]
  then
    benchmark_file_name="${benchmark_name}-tcpdump-benchmark-${thread_count}-${connections}.log"
  fi
  if [[ $input_choice -eq 2 ]]
  then
    benchmark_file_name="${benchmark_name}-jaeger-benchmark-${thread_count}-${connections}.log"
  fi
  if [[ $input_choice -eq 3 ]]
  then
    benchmark_file_name="${benchmark_name}-no-tracing-benchmark-${thread_count}-${connections}.log"
  fi
  if [[ $input_choice -eq 4 ]]
  then
    benchmark_file_name="${benchmark_name}-istio-benchmark-${thread_count}-${connections}.log"
  fi
}

pre_deployment() {
  oc create namespace hotel-res 2>/dev/null
  oc project hotel-res
  if [[ $input_choice -eq 4 ]]
    then
      echo "Enabling Istio on the namespace"
      namespaceStatus=$(oc get ns istio-system -o json | jq .status.phase -r || "Failed")
      if [[ $namespaceStatus != "Active" ]]
      then
        echo "Namespace is not there. Deploying Istio ...."
        sh deploy-istio.sh
      fi
      if [[ $namespaceStatus == "Active" ]]
      then
        echo "Namespace is there. Enabling Istio...."
        oc -n hotel-res create -f istio-attachment.yaml
        oc label namespace hotel-res istio-injection=enabled
      fi
  fi
  if [[ $input_choice -ne 4 ]]
    then
      echo "Disabling Istio on the namespace"
      istioctl uninstall --purge -y
      oc delete namespace istio-system
      oc -n hotel-res delete network-attachment-definition istio-cni
      oc label namespaces hotel-res istio-injection-
  fi
}

deploy_restart_benchmark() {
  #Deploy service if doing from scratch
  if [[ $scratch_choice == [yY] ]]
  then
    oc delete deployment,pods,service,pvc --all --namespace hotel-res
    sleep 60
    oc create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username="$docker_username" --docker-password="$docker_password" --docker-email="$docker_email"
    oc get secret regcred --output=yaml
    sh deploy.sh
    total_pods=$(oc get pods  -n hotel-res --output name | wc -l)
    count_pods=0
    while [ "$count_pods" -ne "$total_pods" ]; do
       count_pods=$(oc get pods  -n hotel-res --output name --field-selector=status.phase=Running | wc -l)
       echo "Watiing for pods to be up..... ${count_pods}/${total_pods}"
       sleep 60
    done
  fi
  #Keep same deployment restart services
  if [[ $scratch_choice == [nN] ]]
  then
    sh softrestart.sh -s 0
    sleep 60
  fi
  if [[ $input_choice -eq 1 ]] || [[ $input_choice -eq 3 ]] || [[ $input_choice -eq 4 ]]
    then
      echo "Disabling jaeger....."
      oc delete -f ../jaeger-deployment.yaml
      oc delete -f ../jaeger-service.yaml
  fi
  if [[ $input_choice -eq 2 ]]
    then
      echo "Enabling jaeger....."
      oc apply -f ../jaeger-deployment.yaml
      oc apply -f ../jaeger-service.yaml
  fi
  echo "Installing ubuntuclient..."
  ubuntuclient=$(oc -n hotel-res get pod | grep ubuntu-client- | cut -f 1 -d " ")
  echo ${ubuntuclient}
#  oc cp "../../../../benchmarks" social-network/"${ubuntuclient}":/root
  oc exec "$ubuntuclient" -- bash -c "cd /root && git clone https://github.com/CASP-Systems-BU/causal-profiling-microservices.git"
  if [[ $benchmark_wrk_version -eq 1 ]]
  then
    oc exec "$ubuntuclient" -- bash -c "cd /root/causal-profiling-microservices/benchmarks/hotelReservation/wrk && make clean && make"
  fi
  if [[ $benchmark_wrk_version -eq 2 ]]
  then
    oc exec "$ubuntuclient" -- bash -c "cd /root/causal-profiling-microservices/benchmarks/hotelReservation/wrk2 && make clean && make"
  fi
  sleep 120
}

pre_benchmark() {
  if [[ $input_choice -eq 1 ]]
  then
      ALL_PODS=$(oc get pod -n hotel-res --field-selector=status.phase=Running -o custom-columns=name:metadata.name --no-headers)
      rm -rf tcpData
      mkdir tcpData
      echo "Starting tcpdump for all pods ....."
      pid_arr=()
      for pod in $ALL_PODS; do
        if [[ ${pod} != *"jaeger"* && ${pod} != *"ubuntu-client"* && ${pod} != *"media-frontend"* ]]
        then
          echo "Starting ksniff on pod: $pod"
          oc sniff -p "$pod" -n hotel-res -o tcpData/output-"$pod".pcap & pid=$!
          pid_arr+=("$pid")
        fi
      done
      sleep 60
      echo "Wait for all ksniff pods to be up...."
      total_pods=$(oc get pods  -n hotel-res --output name | wc -l)
      while [ $(oc get pods  -n hotel-res --output name --field-selector=status.phase=Running | wc -l) -ne "$total_pods" ]; do
         echo "Watiing for pods to be up....."
         sleep 60
      done
  fi
}


post_benchmark() {
  if [[ $input_choice -eq 1 ]]
  then
    echo "Killing all knsiff processes...."
    for value in "${pid_arr[@]}"
    do
         kill -9 "$value"
    done
    echo "Deleting all ksniff pods...."
    oc get pods -n hotel-res -o json > data.json
    oc delete pods -l app=ksniff
    sleep 30
    mergecap -w tcpData/final-output.pcap tcpData/*.pcap
  #  python read-pcap-file.py
  fi
}

run_benchmark() {
  echo "Saving benchmark pod placement"
  oc get pods -n hotel-res -o wide > ${benchmark_output_path}/benchmark-placement/${benchmark_file_name}
  echo "Running workload...."
  if [[ $on_cluster_client == [yY] ]]
  then
    ubuntuclient=$(oc -n hotel-res get pod | grep ubuntu-client- | cut -f 1 -d " ")
    if [[ $benchmark_wrk_version -eq 1 ]]
    then
      oc exec "$ubuntuclient" -- bash -c "cd /root/causal-profiling-microservices/benchmarks/hotelReservation/wrk && \
            ./wrk -t ${thread_count} -c ${connections} -d ${benchmark_duration}s --latency -s scripts/hotel-reservation/mixed-workload_type_1.lua http://frontend.hotel-res.svc.cluster.local:5000" > ${benchmark_output_path}/benchmark-exp-logs/${benchmark_file_name}
    fi
    if [[ $benchmark_wrk_version -eq 2 ]]
    then
      oc exec "$ubuntuclient" -- bash -c "cd /root/causal-profiling-microservices/benchmarks/hotelReservation/wrk2 && \
            ./wrk -D exp -t ${thread_count} -c ${connections} -d ${benchmark_duration}s -R ${total_rps} -L -P -s scripts/hotel-reservation/mixed-workload_type_1.lua http://frontend.hotel-res.svc.cluster.local:5000" > ${benchmark_output_path}/benchmark-exp-logs/${benchmark_file_name}
    fi
  fi
  sleep 1m
}

read -p "Script mode: 1.TCP Dump 2.Jaeger 3.No Jaeger 4. With Istio" input_choice
echo $input_choice
benchmark_name="hotel-reservation"
thread_count=$1
connections=$2
benchmark_duration=$3
total_rps=$4
scratch_choice=$5
benchmark_output_path=$6
on_cluster_client="y"
benchmark_file_name=""
cluster_host_name=".apps.firm.zp7q.p1.openshiftapps.com"
benchmark_wrk_version=2
#Deciding benchmark file name
set_benchmark_file_name
echo "Benchmark file name: ${benchmark_file_name}"
echo "Running benchmark for script mode ${input_choice} for thread count: ${thread_count} connections: ${connections} requests per second: ${total_rps} duration: ${benchmark_duration}"
#if [[ $input_choice -eq 4 ]]
#then
#  run_benchmark
#  exit 0
#fi
#read -p "Start from scratch? Y/N" scratch_choice
echo "Please make sure you have logged in to your kubernetes cluster....."
#Changing config based on choice
if [[ $scratch_choice == [yY] ]]
then
  pre_deployment
  deploy_restart_benchmark
  pre_benchmark
fi
run_benchmark
#post_benchmark