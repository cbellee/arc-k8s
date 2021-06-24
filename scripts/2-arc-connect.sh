LOCATION=australiaeast
RG_NAME=k8s-arc

## Create a resource group to hold the Arc enabled Kubernetes resource
az group create --name $RG_NAME -l $LOCATION -o table

## Connect the Kubernetes cluster to Azure Arc
az connectedk8s connect --name k8s-arc-workshop-cluster --resource-group $RG_NAME

## Open another Command Prompt window and watch for the rollout of agents. 
## Eventually you should have 8 agents in the azure-arc namespace.
kubectl get po -A -w
