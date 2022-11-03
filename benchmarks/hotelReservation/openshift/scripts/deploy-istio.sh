#!/bin/bash

oc adm policy add-scc-to-group anyuid system:serviceaccounts:istio-system
istioctl install -f istio-operator.yaml -y
oc -n istio-system expose svc/istio-ingressgateway --port=http2
oc adm policy add-scc-to-group anyuid system:serviceaccounts:hotel-res
oc -n hotel-res create -f istio-attachment.yaml
oc label namespace hotel-res istio-injection=enabled