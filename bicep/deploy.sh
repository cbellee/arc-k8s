LOCATION=<your location>
ALIAS=<your alias>
RG_NAME=k8s-arc-workshop-${ALIAS}-rg
ADMIN_USER_NAME=localadmin
ADMIN_PASSWORD=<your password>
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)

az group create --location $LOCATION --resource-group $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name k8s-master-deployment \
    --template-file main.bicep \
    --parameters location=$LOCATION alias=$ALIAS adminUserName=$ADMIN_USER_NAME adminPassword=$ADMIN_PASSWORD sshPublicKey="$SSH_KEY" \
    --query '[properties.outputs.fqdn.value, properties.outputs.ipAddress.value, properties.outputs.sshCommand.value, properties.outputs.kubeConfig.value]'
