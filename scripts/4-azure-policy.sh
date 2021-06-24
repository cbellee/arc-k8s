# Provider register: Register the Azure Policy provider
az provider register --namespace 'Microsoft.PolicyInsights'

# get connected cluster id
ARC_CLUSTER_ID=$(az connectedk8s show -g k8s-arc -n k8s-arc-workshop-cluster --query id -o tsv)

# create service principal
SP=$(az ad sp create-for-rbac --role "Policy Insights Data Writer (Preview)" --scopes $ARC_CLUSTER_ID)

# install Azure Policy Helm repo
helm repo add azure-policy https://raw.githubusercontent.com/Azure/azure-policy/master/extensions/policy-addon-kubernetes/helm-charts

helm install azure-policy-addon azure-policy/azure-policy-addon-arc-clusters \
    --set azurepolicy.env.resourceid=$ARC_CLUSTER_ID \
    --set azurepolicy.env.clientid=$(echo $SP | jq '.appId' -r) \
    --set azurepolicy.env.clientsecret=$(echo $SP | jq '.password' -r) \
    --set azurepolicy.env.tenantid=$(echo $SP | jq '.tenant' -r)

# azure-policy pod is installed in kube-system namespace
kubectl get pods -n kube-system

# gatekeeper pod is installed in gatekeeper-system namespace
kubectl get pods -n gatekeeper-system

# Assign a policy from the Azure Portal

# Get the azure-policy pod name installed in kube-system namespace
kubectl logs <azure-policy pod name> -n kube-system

# Get the gatekeeper pod name installed in gatekeeper-system namespace
kubectl logs <gatekeeper pod name> -n gatekeeper-system
