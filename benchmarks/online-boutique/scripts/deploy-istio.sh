#!/bin/bash

oc adm policy add-scc-to-group anyuid system:serviceaccounts:istio-system
istioctl install -f istio-operator.yaml -y
oc -n istio-system expose svc/istio-ingressgateway --port=http2
oc adm policy add-scc-to-group anyuid system:serviceaccounts:online-boutique
oc -n online-boutique create -f istio-attachment.yaml
oc label namespace online-boutique istio-injection=enabled