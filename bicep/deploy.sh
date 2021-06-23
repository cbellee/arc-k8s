LOCATION=australiaeast
ALIAS=cbellee
ADMIN_USER_NAME=localadmin
ADMIN_PASSWORD=P@ssword1234567890
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)

RG_NAME=$(az deployment sub create \
    --location $LOCATION \
    --template-file resourceGroup.bicep \
    --parameters location=$LOCATION alias=$ALIAS \
    --query properties.outputs.resourceGroupName.value)

az deployment group create \
    --resource-group $RG_NAME \
    --name k8s-master-deployment \
    --template-file main.bicep \
    --parameters script="$(cat prepare-cluster-node.sh | gzip -9 | base64 -w0)" command="./prepare-cluster-node.sh --ip=$ --dns" location=$LOCATION alias=$ALIAS adminUserName=$ADMIN_USER_NAME adminPassword=$ADMIN_PASSWORD sshPublicKey="$SSH_KEY" \
    --query 'properties.outputs.sshCommand.value'

#az deployment group show \
#    --resource-group $RG_NAME \
#    --name k8s-master-deployment \
#    --query 'properties.outputs.sshCommand.value' \
#    --output tsv
