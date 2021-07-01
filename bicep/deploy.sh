ALIAS=cbellee
LOCATION=australiaeast
RG_NAME=k8s-arc-workshop-${ALIAS}-rg
ADMIN_USER_NAME=localadmin

# replace with your SSH key pair paths
SSH_KEY_PATH=~/.ssh/
PUBLIC_SSH_KEY=$(cat $SSH_KEY_PATH/id_rsa.pub)

# create resource group
az group create --location $LOCATION --resource-group $RG_NAME

# deploy .bicep file
az deployment group create \
    --resource-group $RG_NAME \
    --name k8s-master-deployment \
    --template-file main.bicep \
    --parameters location=$LOCATION alias=$ALIAS adminUserName=$ADMIN_USER_NAME sshPublicKey="$PUBLIC_SSH_KEY" \
    --query '[properties.outputs.userName.value, properties.outputs.fqdn.value, properties.outputs.ipAddress.value, properties.outputs.sshCommand.value, properties.outputs.kubeConfig.value]'

# get deplyment output variables
OUTPUT=$(az deployment group show \
    --resource-group $RG_NAME \
    --name k8s-master-deployment \
    --query '{userName:properties.outputs.userName.value, fqdn:properties.outputs.fqdn.value, ipAddress:properties.outputs.ipAddress.value, sshCommand:properties.outputs.sshCommand.value}')

# get FQDN & IP Address from output
FQDN=$(echo $OUTPUT | jq '.fqdn' -r)
IP=$(echo $OUTPUT | jq '.ipAddress' -r)

# copy remote kubeconfig file to ~/.kube/config
sudo scp -i $SSH_KEY_PATH/id_rsa $ADMIN_USER_NAME@$FQDN:/tmp/config ~/.kube/config

# replace private IP Address with VM public IP in kubeconfig file
sudo sed -i "s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/${IP}/g" ~/.kube/config
