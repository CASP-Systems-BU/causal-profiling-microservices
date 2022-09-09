#!/bin/bash
input="benchmark-input.txt"
while IFS= read -r line
do
  args=($line)
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" <<< 1
done < "$input"

input="benchmark-input.txt"
while IFS= read -r line
do
  args=($line)
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" <<< 3
done < "$input"

input="benchmark-input.txt"
while IFS= read -r line
do
  args=($line)
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" <<< 2
done < "$input"


input="benchmark-input.txt"
while IFS= read -r line
do
  args=($line)
  hdr-plot --output benchmark-plot/benchmark-"${args[3]}".png --title "Benchmark for ${args[3]} rps" benchmark-exp-logs/experiment-1-${args[3]}.log benchmark-exp-logs/experiment-2-${args[3]}.log benchmark-exp-logs/experiment-3-${args[3]}.log
done < "$input"


hdr-plot --output benchmark-notracing-allrequest-3.png --title "No tracing All RPS" benchmark-exp-logs/experiment-3-20.log benchmark-exp-logs/experiment-3-40.log benchmark-exp-logs/experiment-3-60.log benchmark-exp-logs/experiment-3-80.log benchmark-exp-logs/experiment-3-100.log benchmark-exp-logs/experiment-3-200.log
hdr-plot --output benchmark-jaeger-allrequest-3.png --title "Jaeger All RPS" benchmark-exp-logs/experiment-2-20.log benchmark-exp-logs/experiment-2-40.log benchmark-exp-logs/experiment-2-60.log benchmark-exp-logs/experiment-2-80.log benchmark-exp-logs/experiment-2-100.log benchmark-exp-logs/experiment-2-200.log
hdr-plot --output benchmark-tcpdump-allrequest-3.png --title "TCP Dump All RPS" benchmark-exp-logs/experiment-1-20.log benchmark-exp-logs/experiment-1-40.log benchmark-exp-logs/experiment-1-60.log benchmark-exp-logs/experiment-1-80.log benchmark-exp-logs/experiment-1-100.log benchmark-exp-logs/experiment-1-200.log