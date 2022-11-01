#!/bin/bash
. docker-conf.config

#Config of benchmarks
#{benchmark_name}_config = (namespace,benchmark_folder,path_to_scripts)
social_network_config=("../benchmarks/socialNetwork/openshift/scripts")
hotel_reservation_config=("../benchmarks/hotelReservation/openshift/scripts")
online_boutique_config=("../benchmarks/socialNetwork/online-boutique/scripts")

read -p "Script mode: 1.TCP Dump 2.Jaeger 3.No Jaeger 4. With Istio" input_choice
echo $input_choice
thread_count=$1
connections=$2
benchmark_duration=$3
total_rps=$4
scratch_choice=$5
benchmark_choice=$6
benchmark_location=""
if [[ $benchmark_choice == "social-network" ]]
then
  benchmark_location=${social_network_config[0]}
fi
if [[ $benchmark_choice == "hotel-reservation" ]]
then
  benchmark_location=${hotel_reservation_config[0]}
fi
if [[ $benchmark_choice == "online-boutique" ]]
then
  benchmark_location=${online_boutique_config[0]}
fi
benchmark_output_location=$(realpath .)
#Running appropriate benchmark
sh ${benchmark_location}/run-benchmark.sh ${thread_count} ${connections} ${benchmark_duration} ${total_rps} ${scratch_choice} ${benchmark_output_location}