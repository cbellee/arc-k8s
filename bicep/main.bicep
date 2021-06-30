param location string
param alias string
param adminUserName string
param vmSize string = 'Standard_DS3_v2'
param sshPublicKey string
param imageRef object = {
  offer: 'UbuntuServer'
  publisher: 'Canonical'
  sku: '18.04-LTS'
  version: 'latest'
}

var vnetName = 'k8s-vnet-${alias}'
var subnetName = 'k8s-subnet'
var vmName = 'k8s-master'
var nicName = '${vmName}-nic'
var publicIpAddressName = '${vmName}-vip'
var publicIpAddressDnsName = 'k8s-master-lab-${alias}'
var nsgName = '${vmName}-nsg'

resource vmNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  location: location
  name: nsgName
  properties: {
    securityRules: [
      {
        name: 'allow-inbound-internet-tcp-6443'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '6443'
          direction: 'Inbound'
          priority: 1000
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          description: 'allow inbound TCP traffic from internet to virtual network on port 6443'
        }
      }
      {
        name: 'allow-inbound-internet-tcp-22'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '22'
          direction: 'Inbound'
          priority: 1100
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          description: 'allow inbound TCP traffic from internet to virtual network on port 22'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  location: location
  name: vnetName
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '172.10.0.0/24'
          networkSecurityGroup: {
            id: vmNsg.id
          }
        }
      }
    ]
  }
}

resource vmPublicIpAddress 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  location: location
  name: publicIpAddressName
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: publicIpAddressDnsName
    }
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  location: location
  name: nicName
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
          publicIPAddress: {
            id: vmPublicIpAddress.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  location: location
  name: vmName
  properties: {
    storageProfile: {
      imageReference: imageRef
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          createOption: 'Empty'
          diskSizeGB: 10
          lun: 1
        }
      ]
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    osProfile: {
      adminUsername: adminUserName
      computerName: vmName
      linuxConfiguration: {
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUserName}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
        disablePasswordAuthentication: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
        }
      }
    }
  }
}

resource scriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: vm
  name: 'k8sSetupScript'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    protectedSettings: {
      commandToExecute: 'sh prepare-cluster.sh -d ${vmPublicIpAddress.properties.dnsSettings.fqdn} -i ${vmPublicIpAddress.properties.ipAddress}'
      fileUris: [
        'https://raw.githubusercontent.com/cbellee/arc-k8s/main/bicep/prepare-cluster.sh'
        'https://raw.githubusercontent.com/cbellee/arc-k8s/main/bicep/install-cluster.sh'
      ]
    }
  }
}

output sshCommand string = 'ssh ${adminUserName}@${vmPublicIpAddress.properties.dnsSettings.fqdn}'
output userName string = adminUserName
output kubeConfig string = scriptExtension.properties.instanceView.statuses[0].message
output fqdn string = vmPublicIpAddress.properties.dnsSettings.fqdn
output ipAddress string = vmPublicIpAddress.properties.ipAddress
