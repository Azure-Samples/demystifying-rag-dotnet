targetScope = 'subscription'

@description('Name of the Azure Developer CLI environment')
@minLength(1)
@maxLength(64)
param environmentName string

@description('Primary location for all resources')
param location string

@description('ID of the principal')
param principalId string = ''

var tags = { 'azd-env-name': environmentName }
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Organize resources in a resource group 
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module openAI 'br/public:ai/cognitiveservices:1.0.5' = {
  name: 'openai'
  scope: resourceGroup
  params: {
    skuName: 'S0'
    kind: 'OpenAI'
    name: 'openai-${resourceToken}'
    location: location
    roleAssignments: [
      {
        principalIds: [
          principalId
        ]
        principalType: 'User'
        roleDefinitionIdOrName: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
      }
    ]
    deployments: [
      {
        name: 'Gpt35Turbo_0301'
        sku: {
          name: 'Standard'
          capacity: 30
        }
        properties: {
          model: {
            format: 'OpenAI'
            name: 'gpt-35-turbo'
            version: '0301'
          }
        }
      }
      {
        name: 'TextEmbeddingAda002_1'
        sku: {
          name: 'Standard'
          capacity: 30
        }
        properties: {
          model: {
            format: 'OpenAI'
            name: 'text-embedding-ada-002'
            version: '2'
          }
        }
      }
    ]
  }
}

output AZURE_LOCATION string = location
output AZURE_OPENAI_ENDPOINT string = openAI.outputs.endpoint
output AZURE_RESOURCE_GROUP string = resourceGroup.name
output AZURE_TENANT_ID string = tenant().tenantId
