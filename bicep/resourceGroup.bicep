param location string
param name string


targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: name
  properties: {}
}

output resourceGroupName string = name
