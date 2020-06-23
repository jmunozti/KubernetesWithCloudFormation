#!/usr/bin/env bash

echo "Prerequisites"
echo "1.- Access to K8 Cluster"
echo "2.- Kubectl"
echo "3.- Helm3"

echo "Begin"

cd /home/jorge/nearsoft/k8s/iac

SSH_KEY="/home/jorge/nearsoft/k8s/iac/jorge.pem"; scp -i $SSH_KEY -o ProxyCommand="ssh -i \"${SSH_KEY}\" ubuntu@${1} nc %h %p" ubuntu@$2:~/kubeconfig ./kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig

#Get cluster info
echo "Get cluster info"
kubectl cluster info
kubectl get all
sleep 20

#Adding Helm3 repo
echo "Adding Helm3 repo"
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
sleep 20

#Install Ingress
echo "Install Ingress"
kubectl create ns nginx
helm install nginx stable/nginx-ingress --namespace nginx --set rbac.create=true --set controller.publishService.enabled=true
kubectl --namespace nginx get services -o wide -w nginx-nginx-ingress-controller
sleep 20

#Deploying an app
echo "Deploying an app"
kubectl create deployment hello-app --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment hello-app --port 8080 --target-port 8080
kubectl apply -f hello-app-ingress.yaml
sleep 20

#Deploying some apps with Helm3
echo "Deploying some apps with Helm3"
helm install --values mychart/values.yaml mychart/ --generate-name
kubectl create ns monitoring
helm install prometheus stable/prometheus --namespace monitoring
kubectl --namespace default get pods -l "release=my-prometheus-operator"
helm list
sleep 20

echo "Get all"
kubectl get all

echo "End"
