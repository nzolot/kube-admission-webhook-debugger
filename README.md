# kube-admission-webhook-debugger

A debugging project which can be installed as admission webhook in to kubernetes. Provides detailed logs which helps to troubleshoot, debug and improve webhook functionality


Can be used as base for other webhooks


## Deployment
Run deployment script `./_deploy.sh`

This script will generate SSL certificates and deploy kubernetes resources. For detailed resource list please take a look at `deployment/template-deployment.yaml`


## Build docker image

`TAG=0.0.11; docker build -t nzolot/kube-admission-webhook-debugger:${TAG} . && docker push nzolot/kube-admission-webhook-debugger:${TAG}`

