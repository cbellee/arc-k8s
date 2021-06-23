LOCATION=australiaeast
ALIAS=cbellee
PREFIX=k8s-workshop
RG_NAME=$PREFIX-rg
VNET_NAME=$PREFIX-vnet
USER_NAME=azureuser

## Create a resource group
az group create --name $RG_NAME --location $LOCATION
    
## Create a VNet and make a note of SUBNETID
az network vnet create --name $VNET_NAME \
--resource-group $RG_NAME \
--location  $LOCATION \
--address-prefixes 172.10.0.0/16 \
--subnet-name $PREFIX-subnet-1 --subnet-prefixes 172.10.1.0/24

SUBNET_ID=$(az network vnet subnet list --resource-group $RG_NAME --vnet-name $VNET_NAME --query "[?name=='$PREFIX-subnet-1'].id" --output tsv)

echo "SUBNET_ID: $SUBNET_ID"

## Create a VM and make a note the fqdns and the public IP address
## Update the placeholders for ALIAS and SUBNETID
az vm create \
--name kube-master \
--resource-group $RG_NAME \
--location $LOCATION \
--image UbuntuLTS \
--admin-user $USER_NAME \
--authentication-type ssh \
--ssh-key-values ~/.ssh/id_rsa.pub \
--size Standard_DS3_v2 \
--data-disk-sizes-gb 10 \
--public-ip-address-dns-name k8s-kube-master-lab-$ALIAS \
--subnet $SUBNET_ID

VM_FQDN=$(az vm show -d --resource-group $RG_NAME --name kube-master --query fqdns -o tsv)
echo "SSH: $USER_NAME@$VM_FQDN"
