## Add the azcli extensions
az extension add --name connectedk8s
az extension add --name k8s-extension

## Register the providers
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.ExtendedLocation

## Monitor the registration process. Registration may take up to 10 minutes.
az provider show -n Microsoft.Kubernetes -o table
az provider show -n Microsoft.KubernetesConfiguration -o table
az provider show -n Microsoft.ExtendedLocation -o table
