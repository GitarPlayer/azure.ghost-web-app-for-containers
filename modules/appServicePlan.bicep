targetScope = 'resourceGroup'

@description('App Service Plan name')
@minLength(1)
@maxLength(40)
param appServicePlanName string

@description('App Service Plan pricing tier')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
])
param appServicePlanSku string

@description('Location to deploy the resources')
param location string = resourceGroup().location

@description('Log Analytics workspace id to use for diagnostics settings')
param logAnalyticsWorkspaceId string

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
    zoneRedundant: true
  }
  sku: {
    name: appServicePlanSku
  }
}

resource appServicePlanDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: appServicePlan
  name: 'AppServicePlanDiagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output id string = appServicePlan.id



resource ghostaspzuebgtmgleAutoscale 'Microsoft.Insights/autoscalesettings@2021-05-01-preview' = {
  name: 'ghost-asp-z6uebgtm2gle6-Autoscale-780'
  location: 'West Europe'
  properties: {
    profiles: [
      {
        name: 'Auto created scale condition'
        capacity: {
          minimum: '1'
          maximum: '10'
          default: '3'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'microsoft.web/serverfarms'
              metricResourceUri: '/subscriptions/2221643b-928c-42a5-a96d-b56de5a8d6d8/resourceGroups/withouthAnd/providers/Microsoft.Web/serverFarms/ghost-asp-z6uebgtm2gle6'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: '70.0'
              dimensions: [
                {
                  DimensionName: 'Instance'
                  Operator: 'Equals'
                  Values: [
                    'pl0ldlwk0001X5'
                  ]
                }
              ]
              dividePerInstance: false
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '3'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
    enabled: true
    name: 'ghost-asp-z6uebgtm2gle6-Autoscale-780'
    targetResourceUri: '/subscriptions/2221643b-928c-42a5-a96d-b56de5a8d6d8/resourceGroups/withouthAnd/providers/Microsoft.Web/serverfarms/ghost-asp-z6uebgtm2gle6'
    notifications: []
    predictiveAutoscalePolicy: {
      scaleMode: 'Disabled'
    }
  }
}
