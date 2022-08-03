targetScope = 'resourceGroup'

param webAppName string

param applicationInsightsInstrumentationKey string

param applicationInsightsConnectionString string

@description('MySQL server hostname')
param databaseHostFQDN string

@description('Ghost datbase name')
param databaseName string

@description('Ghost database user name')
param databaseLogin string

@description('Ghost database user password')
param databasePasswordSecretUri string

@description('Website URL to autogenerate links by Ghost')
param siteUrl string

@description('Mount path for Ghost content files')
param containerMountPath string

@description('Container registry to pull Ghost docker image')
param containerRegistryUrl string

resource existingWebApp 'Microsoft.Web/sites@2020-09-01' existing = {
  name: webAppName
}

resource webAppSettings 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: existingWebApp
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsightsInstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
    XDT_MicrosoftApplicationInsights_Mode: 'default'
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
    DOCKER_REGISTRY_SERVER_URL: containerRegistryUrl
    // Ghost-specific settings
    NODE_ENV: 'production'
    GHOST_CONTENT: containerMountPath
    paths__contentPath: containerMountPath
    privacy_useUpdateCheck: 'false'
    url: siteUrl
    database__client: 'mysql'
    database__connection__host: databaseHostFQDN
    database__connection__user: databaseLogin
    database__connection__password: '@Microsoft.KeyVault(SecretUri=${databasePasswordSecretUri})'
    database__connection__database: databaseName
    database__connection__ssl: 'true'
    database__connection__ssl_minVersion: 'TLSv1.2'
  }
}



@description('Generated from /subscriptions/2221643b-928c-42a5-a96d-b56de5a8d6d8/resourceGroups/withouthand/providers/Microsoft.Web/sites/ghost-web-z6uebgtm2gle6/slots/Stage')
resource Stage 'Microsoft.Web/sites/slots@2022-03-01' = {
  name: 'ghost-web-z6uebgtm2gle6/Stage'
  kind: 'app,linux,container'
  location: 'West Europe'
  properties: {
    enabled: true
    adminEnabled: true
    siteProperties: {
      metadata: null
      properties: [
        {
          name: 'LinuxFxVersion'
          value: 'DOCKER|gitarplayer/ghost-az-ai:stage'
        }
        {
          name: 'WindowsFxVersion'
          value: null
        }
      ]
      appSettings: null
    }

    serverFarmId: '/subscriptions/2221643b-928c-42a5-a96d-b56de5a8d6d8/resourceGroups/withouthAnd/providers/Microsoft.Web/serverfarms/ghost-asp-z6uebgtm2gle6'
    reserved: true
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'DOCKER|gitarplayer/ghost-az-ai:stage'
      acrUseManagedIdentityCreds: false
      alwaysOn: true
      http20Enabled: true
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    customDomainVerificationId: 'E5533B929A5EF074C49BB8EC25AB12AF96B22DAF39DDD500A4A5DA5EF32647C0'
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}
