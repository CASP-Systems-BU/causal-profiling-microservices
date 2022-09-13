#!/bin/bash
#input="benchmark-input.txt"
#while IFS= read -r line
#do
#  args=($line)
#  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" y <<< 3
#  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" n <<< 1
#  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" n <<< 2
#  hdr-plot --output benchmark-plot/benchmark-"${args[3]}".png --title "Benchmark for ${args[3]} rps" benchmark-exp-logs/tcpdump-benchmark-${args[3]}.log benchmark-exp-logs/jaeger-benchmark-${args[3]}.log benchmark-exp-logs/no-tracing-benchmark-${args[3]}.log
#done < "$input"

#Running same benchmark multiple times for same type
input="benchmark-input.txt"
while IFS= read -r line
do
  file_args=""
  args=($line)
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" y <<< 1
  for (( c=1; c<=6; c++ ))
  do
    file_args+="benchmark-exp-logs/no-tracing-exp/tcpdump-benchmark-${args[3]}-${c}.log "
    ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" n <<< 1
    cp benchmark-exp-logs/tcpdump-benchmark-${args[3]}.log benchmark-exp-logs/no-tracing-exp/tcpdump-benchmark-${args[3]}-${c}.log
  done
  hdr-plot --output benchmark-plot/benchmark-tcpdump-exp-"${args[3]}".png --title "Tcpdump Benchmark for ${args[3]} rps" $file_args
done < "$input"

#input="benchmark-input.txt"
#while IFS= read -r line
#do
#  args=($line)
#  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" y <<< 3
#done < "$input"
#
#input="benchmark-input.txt"
#while IFS= read -r line
#do
#  args=($line)
#  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" n <<< 1
#done < "$input"
#
#input="benchmark-input.txt"
#while IFS= read -r line
#do
#  args=($line)
#  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" n <<< 2
#done < "$input"


#input="benchmark-input.txt"
#while IFS= read -r line
#do
#  args=($line)
#  hdr-plot --output benchmark-plot/benchmark-"${args[3]}".png --title "Benchmark for ${args[3]} rps" benchmark-exp-logs/tcpdump-benchmark-${args[3]}.log benchmark-exp-logs/jaeger-benchmark-${args[3]}.log benchmark-exp-logs/no-tracing-benchmark-${args[3]}.log
#done < "$input"

#hdr-plot --output benchmark-notracing-allrequest-3.png --title "No tracing All RPS" benchmark-exp-logs/no-tracing-benchmark-20.log benchmark-exp-logs/no-tracing-benchmark-40.log benchmark-exp-logs/no-tracing-benchmark-60.log benchmark-exp-logs/no-tracing-benchmark-80.log benchmark-exp-logs/no-tracing-benchmark-100.log benchmark-exp-logs/no-tracing-benchmark-200.log
#hdr-plot --output benchmark-jaeger-allrequest-3.png --title "Jaeger All RPS" benchmark-exp-logs/jaeger-benchmark-20.log benchmark-exp-logs/jaeger-benchmark-40.log benchmark-exp-logs/jaeger-benchmark-60.log benchmark-exp-logs/jaeger-benchmark-80.log benchmark-exp-logs/jaeger-benchmark-100.log benchmark-exp-logs/jaeger-benchmark-200.log
#hdr-plot --output benchmark-tcpdump-allrequest-3.png --title "TCP Dump All RPS" benchmark-exp-logs/tcpdump-benchmark-20.log benchmark-exp-logs/tcpdump-benchmark-40.log benchmark-exp-logs/tcpdump-benchmark-60.log benchmark-exp-logs/tcpdump-benchmark-80.log benchmark-exp-logs/tcpdump-benchmark-100.log benchmark-exp-logs/tcpdump-benchmark-200.log