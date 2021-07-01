ALIAS=cbellee
LOCATION=australiaeast
RG_NAME=k8s-arc-workshop-${ALIAS}-rg
ADMIN_USER_NAME=localadmin
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)

az group create --location $LOCATION --resource-group $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name k8s-master-deployment \
    --template-file main.bicep \
    --parameters location=$LOCATION alias=$ALIAS adminUserName=$ADMIN_USER_NAME sshPublicKey="$SSH_KEY" \
    --query '[properties.outputs.userName.value, properties.outputs.fqdn.value, properties.outputs.ipAddress.value, properties.outputs.sshCommand.value, properties.outputs.kubeConfig.value]'

OUTPUT=$(az deployment group show \
    --resource-group $RG_NAME \
    --name k8s-master-deployment \
    --query '{userName:properties.outputs.userName.value, fqdn:properties.outputs.fqdn.value, ipAddress:properties.outputs.ipAddress.value, sshCommand:properties.outputs.sshCommand.value}')

FQDN=$(echo $OUTPUT | jq '.fqdn' -r)

# ssh $ADMIN_USER_NAME@$FQDN

# copy remote kubeconfig file to ~/.kube/config
sudo scp -i ~/.ssh/id_rsa $ADMIN_USER_NAME@$FQDN:/tmp/config ~/.kube/config
