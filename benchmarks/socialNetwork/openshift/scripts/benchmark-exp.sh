#!/bin/bash
input="benchmark-input.txt"
while IFS= read -r line
do
  args=($line)
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" <<< 1
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" <<< 2
  ./get-tcpdump-all-pods.sh "${args[0]}" "${args[1]}" "${args[2]}" <<< 3
done < "$input"