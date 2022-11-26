#!/bin/bash


input_choice=$1

NS=online-boutique

cd $(dirname $0)/..

oc create namespace ${NS} 2>/dev/null
oc project ${NS}

oc adm policy add-scc-to-user anyuid -z default -n ${NS}
oc adm policy add-scc-to-user privileged -z default -n ${NS}
oc policy add-role-to-user system:image-puller system:serviceaccount:online-boutique:default -n online-boutique
oc policy add-role-to-user system:image-puller kube:admin -n online-boutique

oc policy add-role-to-user system:image-builder kube:admin -n online-boutique
oc policy add-role-to-user registry-viewer kube:admin -n online-boutique
oc policy add-role-to-user registry-editor kube:admin -n online-boutique

oc create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username="$docker_username" --docker-password="$docker_password" --docker-email="$docker_email"
oc get secret regcred --output=yaml
oc apply -f hr-client.yaml
if [[ $input_choice -eq 1 ]] || [[ $input_choice -eq 3 ]] || [[ $input_choice -eq 4 ]]
then
  echo "Deploying non Jaeger version"
  oc apply -f kubernetes-manifests.yaml
fi
if [[ $input_choice -eq 2 ]]
then
  echo "Deploying Jaeger version"
  oc apply -f jaeger-deployment.yaml
  oc apply -f jaeger-service.yaml
  oc apply -f kubernetes-manifests-jaeger.yaml
fi
if [[ $input_choice -eq 4 ]]
then
  echo "Deploying Istio files"
  oc apply -f istio-manifests.yaml
fi
wait

echo "Finishing in 30 seconds"
sleep 30

oc get pods -n ${NS}

cd - >/dev/null

