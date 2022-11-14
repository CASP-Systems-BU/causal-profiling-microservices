#!/bin/bash
. docker-conf.config

set_benchmark_file_name() {
  if [[ $input_choice -eq 1 ]]
  then
    benchmark_file_name="${benchmark_name}-tcpdump-benchmark-${total_rps}.log"
  fi
  if [[ $input_choice -eq 2 ]]
  then
    benchmark_file_name="${benchmark_name}-jaeger-benchmark-${total_rps}.log"
  fi
  if [[ $input_choice -eq 3 ]]
  then
    benchmark_file_name="${benchmark_name}-no-tracing-benchmark-${total_rps}.log"
  fi
  if [[ $input_choice -eq 4 ]]
  then
    benchmark_file_name="${benchmark_name}-istio-benchmark-${total_rps}.log"
  fi
}

pre_deployment() {
  oc apply -f ../social-network-ns.yaml
  oc project social-network
  if [[ $input_choice -eq 1 ]] || [[ $input_choice -eq 3 ]] || [[ $input_choice -eq 4 ]]
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
        oc -n social-network create -f istio-attachment.yaml
        oc label namespace social-network istio-injection=enabled
      fi
  fi
  if [[ $input_choice -ne 4 ]]
    then
      echo "Disabling Istio on the namespace"
      istioctl uninstall --purge -y
      oc delete namespace istio-system
      oc -n social-network delete network-attachment-definition istio-cni
      oc label namespaces social-network istio-injection-
  fi
}

deploy_restart_benchmark() {
  #Deploy service if doing from scratch
  if [[ $scratch_choice == [yY] ]]
  then
    oc delete all --all --namespace social-network
    sleep 60
    sh configmaps/update-jaeger-configmap.sh
    oc create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username="$docker_username" --docker-password="$docker_password" --docker-email="$docker_email"
    oc get secret regcred --output=yaml
    sh deploy-all-services-and-configurations.sh
    total_pods=$(oc get pods  -n social-network --output name | wc -l)
    count_pods=0
    while [ "$count_pods" -ne "$total_pods" ]; do
       count_pods=$(oc get pods  -n social-network --output name --field-selector=status.phase=Running | wc -l)
       echo "Watiing for pods to be up..... ${count_pods}/${total_pods}"
       sleep 60
    done
  fi
  #Keep same deployment restart services
  if [[ $scratch_choice == [nN] ]]
  then
    sh configmaps/update-jaeger-configmap.sh
    sh restartall.sh -s 0 -i 0
    sleep 60
  fi
  echo "Installing ubuntuclient..."
  ubuntuclient=$(oc -n social-network get pod | grep ubuntu-client- | cut -f 1 -d " ")
  echo ${ubuntuclient}
#  oc cp "../../../../benchmarks" social-network/"${ubuntuclient}":/root
  oc exec "$ubuntuclient" -- bash -c "cd /root && git clone https://github.com/CASP-Systems-BU/causal-profiling-microservices.git"
  if [[ $benchmark_wrk_version -eq 1 ]]
    then
      oc exec "$ubuntuclient" -- bash -c "cd /root/causal-profiling-microservices/benchmarks/socialNetwork/wrk && make clean && make"
    fi
    if [[ $benchmark_wrk_version -eq 2 ]]
    then
      oc exec "$ubuntuclient" -- bash -c "cd /root/causal-profiling-microservices/benchmarks/socialNetwork/wrk2 && make clean && make"
    fi
  oc exec "$ubuntuclient" -- bash -c "cd /root/causal-profiling-microservices/benchmarks/socialNetwork && python3 scripts/init_social_graph.py"
  sleep 120
}

pre_benchmark() {
  if [[ $input_choice -eq 1 ]]
  then
      ALL_PODS=$(oc get pod -n social-network --field-selector=status.phase=Running -o custom-columns=name:metadata.name --no-headers)
      rm -rf tcpData
      mkdir tcpData
      echo "Starting tcpdump for all pods ....."
      pid_arr=()
      for pod in $ALL_PODS; do
        if [[ ${pod} != *"jaeger"* && ${pod} != *"ubuntu-client"* && ${pod} != *"media-frontend"* ]]
        then
          echo "Starting ksniff on pod: $pod"
          oc sniff -p "$pod" -n social-network -o tcpData/output-"$pod".pcap & pid=$!
          pid_arr+=("$pid")
        fi
      done
      sleep 60
      echo "Wait for all ksniff pods to be up...."
      total_pods=$(oc get pods  -n social-network --output name | wc -l)
      while [ $(oc get pods  -n social-network --output name --field-selector=status.phase=Running | wc -l) -ne "$total_pods" ]; do
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
    oc get pods -n social-network -o json > data.json
    oc delete pods -l app=ksniff
    sleep 30
    mergecap -w tcpData/final-output.pcap tcpData/*.pcap
  #  python read-pcap-file.py
  fi
}

run_benchmark() {
  echo "Saving benchmark pod placement"
  oc get pods -n social-network -o wide > ${benchmark_output_path}/benchmark-placement/${benchmark_file_name}
  echo "Running workload...."
  if [[ $on_cluster_client == [yY] ]]
  then
    ubuntuclient=$(oc -n social-network get pod | grep ubuntu-client- | cut -f 1 -d " ")
    if [[ $benchmark_wrk_version -eq 1 ]]
    then
      oc exec "$ubuntuclient" -- bash -c "cd /root/causal-profiling-microservices/benchmarks/socialNetwork/wrk && \
          ./wrk -t ${thread_count} -c ${connections} -d ${benchmark_duration}s --latency -s ./scripts/social-network/read-user-timeline.lua http://nginx-thrift.social-network.svc.cluster.local:8080/wrk2-api/user-timeline/read" > ${benchmark_output_path}/benchmark-exp-logs/${benchmark_file_name}
    fi
    if [[ $benchmark_wrk_version -eq 2 ]]
    then
      oc exec "$ubuntuclient" -- bash -c "cd /root/causal-profiling-microservices/benchmarks/socialNetwork/wrk2 && \
          ./wrk -D exp -t ${thread_count} -c ${connections} -d ${benchmark_duration}s -R ${total_rps} -L -P -s ./scripts/social-network/read-user-timeline.lua http://nginx-thrift.social-network.svc.cluster.local:8080/wrk2-api/user-timeline/read" > ${benchmark_output_path}/benchmark-exp-logs/${benchmark_file_name}
    fi
  fi
  if [[ $on_cluster_client == [nN] ]]
  then
    cd ../../wrk2
    sed -i "s+http://localhost:8080+http://nginx-thrift-social-network${cluster_host_name}+g" ./scripts/social-network/read-user-timeline.lua
    ./wrk -D exp -t ${thread_count} -c ${connections} -d ${benchmark_duration}s -R ${total_rps} -L -P -s ./scripts/social-network/read-user-timeline.lua http://nginx-thrift-social-network${cluster_host_name}/wrk2-api/user-timeline/read > ${benchmark_output_path}/benchmark-exp-logs/${benchmark_file_name}
    cd -
    pwd
  fi
  sleep 1m
}

read -p "Script mode: 1.TCP Dump 2.Jaeger 3.No Jaeger 4. With Istio" input_choice
echo $input_choice
benchmark_name="social-network"
thread_count=$1
connections=$2
benchmark_duration=$3
total_rps=$4
scratch_choice=$5
benchmark_output_path=$6
on_cluster_client="y"
benchmark_file_name=""
benchmark_wrk_version=1
cluster_host_name=".apps.firm.zp7q.p1.openshiftapps.com"
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
pre_deployment
deploy_restart_benchmark
pre_benchmark
run_benchmark
post_benchmark