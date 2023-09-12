targetScope = 'subscription'

@description('Name of the environment used to generate a short unique hash for resources.')
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
resource group 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module openAI 'br/public:ai/cognitiveservices:1.1.1' = {
  name: 'openai'
  scope: group
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

module searchService 'br/public:search/search-service:1.0.1' = {
  name: 'search-service'
  scope: group
  params: {
    name: 'search-${resourceToken}'
    location: location
    tags: tags
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    sku: {
      name: 'standard'
    }
    semanticSearch: 'free'
  }
}

var searchRoleDefId = '1407120a-92aa-4202-b7e9-c0e197c71c8f'
module searchServiceRole 'br/public:authorization/resource-scope-role-assignment:1.0.2' = {
  scope: group
  name: 'search-service-role'
  params: {
    name: guid(subscription().id, group.id, principalId, searchRoleDefId)
    principalId: principalId
    resourceId: searchService.outputs.id
    roleDefinitionId: searchRoleDefId
  }
}

output AZURE_LOCATION string = location
output AZURE_OPENAI_ENDPOINT string = openAI.outputs.endpoint
output AZURE_RESOURCE_GROUP string = group.name
output AZURE_TENANT_ID string = tenant().tenantId
