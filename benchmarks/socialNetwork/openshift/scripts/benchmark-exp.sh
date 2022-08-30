#!/bin/bash
input="benchmark-input.txt"
while IFS= read -r line
do
  args=($line)
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" <<< 1
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" <<< 3
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" "${args[3]}" <<< 2
done < "$input"