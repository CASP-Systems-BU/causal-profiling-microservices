#!/bin/bash
input="benchmark-input.txt"
while IFS= read -r line
do
  args=($line)
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" <<< 1
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" <<< 3
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" <<< 2
  hdr-plot --output benchmark-plot/benchmark-"${args[3]}".png --title "Benchmark for ${args[3]} rps" benchmark-exp-logs/experiment-1-${args[3]}.log benchmark-exp-logs/experiment-2-${args[3]}.log benchmark-exp-logs/experiment-3-${args[3]}.log
done < "$input"