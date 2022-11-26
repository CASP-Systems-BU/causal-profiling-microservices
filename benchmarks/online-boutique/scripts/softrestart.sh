#!/bin/bash

NS=online-boutique

function finish {
cd $(dirname $0)/../..

cd -
}

function usage()
{
    echo    "Restart Containers"
    echo
    echo -e "\t-h --help"
    echo -e "\t-s --show-update watch the pods creation (default true)"
}

if [[ -z $@ ]]; then
  echo "No parameter specified, use '"-h"' to see all available configurations"
fi

while [ "$1" != "" ]; do
    PARAM=$1; shift
    VALUE=$1; shift
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -s | --show-update)
            SHOW_UPDATE=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
done

WORK="emailservice checkoutservice recommendationservice frontend paymentservice productcatalogservice cartservice currencyservice shippingservice redis-cart adservice ubuntu-client"


echo this may take a while ... use control-c when status screen shows all services up.
echo reducing replicas to 0

for d in ${WORK}
do
	oc scale --replicas=0 deployment/$d -n ${NS} &
done

wait

echo increasing replicas back to 1
for d in ${WORK}
do
	oc scale --replicas=1 deployment/$d -n ${NS} &
done

wait

if [[ -z $SHOW_UPDATE ]] || [[ $(echo $SHOW_UPDATE | egrep "1|true" |wc -l) -gt 0 ]]; then
  echo now wait for everything to come back up
  watch oc get pods -n ${NS}
else
  running=$(oc get pods -n ${NS} --no-headers | grep Running |wc -l)
  while [[ $running -lt 20 ]]; do
    echo "Waiting for $(echo 20-$running|bc) pods to start"
    sleep 1
    running=$(oc get pods -n ${NS} --no-headers | grep Running |wc -l)
  done
fi
