#!/bin/bash

cd $(dirname $0)/..
NS="online-boutique"

oc create namespace ${NS}
oc project ${NS}
oc adm policy add-scc-to-user anyuid -z default -n ${NS}
oc adm policy add-scc-to-user privileged -z default -n ${NS}
oc apply -f kubernetes-manifests.yaml

cd - >/dev/null