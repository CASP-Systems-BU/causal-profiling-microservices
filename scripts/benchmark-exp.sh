#!/bin/bash
input="benchmark-input.txt"
benchmark_choice="social-network"
while IFS= read -r line
do
  args=($line)
  ./run-benchmark.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" y "${benchmark_choice}" <<< 3
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" n "${benchmark_choice}" <<< 1
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" n "${benchmark_choice}" <<< 2
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" y "${benchmark_choice}" <<< 4
  hdr-plot --output benchmark-plot/${benchmark_choice}-benchmark-"${args[3]}".png --title "${benchmark_choice}: Benchmark for ${args[3]} rps" benchmark-exp-logs/${benchmark_choice}-tcpdump-benchmark-${args[3]}.log benchmark-exp-logs/${benchmark_choice}-jaeger-benchmark-${args[3]}.log benchmark-exp-logs/${benchmark_choice}-no-tracing-benchmark-${args[3]}.log benchmark-exp-logs/${benchmark_choice}-istio-benchmark-${args[3]}.log
done < "$input"