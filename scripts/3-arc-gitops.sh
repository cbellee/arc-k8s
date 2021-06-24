# apply configuration in repo
az k8s-configuration create \
--name cluster-config \
--cluster-name k8s-arc-workshop-cluster \
--resource-group k8s-arc \
--operator-instance-name cluster-config \
--operator-namespace cluster-config \
--repository-url https://github.com/Azure/arc-k8s-demo \
--scope cluster \
--cluster-type connectedClusters


# validate
az k8s-configuration show \
--name cluster-config \
--cluster-name k8s-arc-workshop-cluster \
--resource-group k8s-arc \
--cluster-type connectedClusters

# validate Kubernetes configuration
kubectl get ns --show-labels
kubectl -n cluster-config get deploy -o wide

kubectl -n team-a get cm -o yaml
kubectl -n itops get all