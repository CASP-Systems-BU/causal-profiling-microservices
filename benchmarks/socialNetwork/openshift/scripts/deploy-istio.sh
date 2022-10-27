#!/bin/bash

oc adm policy add-scc-to-group anyuid system:serviceaccounts:istio-system
istioctl install --set profile=openshift -y
oc -n istio-system expose svc/istio-ingressgateway --port=http2
oc adm policy add-scc-to-group anyuid system:serviceaccounts:social-network
oc -n social-network create -f istio-attachment.yaml
oc label namespace social-network istio-injection=enabled