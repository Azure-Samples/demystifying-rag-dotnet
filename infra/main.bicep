targetScope = 'subscription'

@description('Name of the environment used to generate a short unique hash for resources.')
@minLength(1)
@maxLength(64)
param environmentName string

@description('Primary location for all resources')
param location string

var tags = { 'azd-env-name': environmentName }
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Organize resources in a resource group 
resource group 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module openAI 'br/public:ai/cognitiveservices:1.1.1' = {
  name: 'openai'
  scope: group
  params: {
    tags: tags
    skuName: 'S0'
    kind: 'OpenAI'
    name: 'openai-${resourceToken}'
    location: location
    deployments: [
      {
        name: 'Gpt35Turbo_0301'
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
        properties: {
          model: {
            format: 'OpenAI'
            name: 'text-embedding-ada-002'
            version: '2'
          }
        }
      }
      {
        name: 'Gpt35Turbo_16k'
        properties: {
          model: {
            format: 'OpenAI'
            name: 'gpt-35-turbo-16k'
            version: '0613'
          }
        }
      }
    ]
  }
}

module searchService 'br/public:search/search-service:1.0.2' = {
  name: 'search-service'
  scope: group
  params: {
    name: 'search-${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'free'
    }
  }
}

output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = group.name
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_OPENAI_ENDPOINT string = openAI.outputs.endpoint
output AZURE_SEARCH_ENDPOINT string = searchService.outputs.endpoint
