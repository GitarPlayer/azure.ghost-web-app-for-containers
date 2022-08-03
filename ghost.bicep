targetScope = 'resourceGroup'

@description('Prefix to use when creating the resources in this deployment.')
param applicationNamePrefix string = 'ghost'

@description('App Service Plan pricing tier')
param appServicePlanSku string = 'B1'


@description('App Service Plan pricing tier for dev')
param devAppServicePlanSku string = 'B1'

@description('Log Analytics workspace pricing tier')
param logAnalyticsWorkspaceSku string = 'PerGB2018'

@description('Storage account pricing tier')
param storageAccountSku string = 'Standard_LRS'

@description('Storage account pricing tier for dev')
param devStorageAccountSku string = 'Standard_LRS'

@description('Location to deploy the resources')
param location string = resourceGroup().location

@description('MySQL server SKU')
param mySQLServerSku string = 'mySQLServerSku'

@description('MySQL server SKU for dev')
param devMySQLServerSku string = 'mySQLServerSku'


@description('MySQL server password')
@secure()
param databasePassword string


@description('MySQL server password for dev')
@secure()
param devDatabasePassword string


@allowed([
  'Disabled'
  'Enabled'
])
@description('Whether or not geo redundant backup is enabled.')
param geoRedundantBackup string

@allowed([
  'Disabled'
  'Enabled'
])
@description('Whether or not geo redundant backup is enabled for dev')
param devGeoRedundantBackup string


@allowed([
  'Disabled'
  'SameZone'
  'ZoneRedundant'
])
@description('High availability mode for a server.')
param highAvailabilityMode string


@allowed([
  'Disabled'
  'SameZone'
  'ZoneRedundant'
])
@description('High availability mode for a server for dev')
param devHighAvailabilityMode string


@description('Ghost container full image name and tag')
param ghostContainerName string = 'gitarplayer/ghost-az-ai'

@allowed([
  'latest'
  'stage'
  'prod'
])
@description('Ghost container full image name and tag')
param ghostContainerTag string 

@description('Container registry where the image is hosted')
param containerRegistryUrl string = 'https://index.docker.io/v1'

@allowed([
  'Web app with Azure CDN'
  'Web app with Azure Front Door'
  'Web app dev'
])
param deploymentConfiguration string = 'Web app with Azure Front Door'

@minValue(30)
@maxValue(730)
param retentionInDays int = 90


@minValue(30)
@maxValue(730)
param devRetentionInDays int = 30


@allowed([
  'v4.0'
  'v5.0'
])
@description('The ghost API version used for the azure function')
param ghostApiVersion string


@allowed([
  'v4.0'
  'v5.0'
])
@description('The ghost API version used for the azure function for dev')
param devGhostApiVersion string

param pkgURL string = 'https://github.com/GitarPlayer/azure-function-ghost/archive/refs/tags/0.0.6.zip'
param devPkgURL string = 'https://github.com/GitarPlayer/azure-function-ghost/archive/refs/tags/0.0.6.zip'


// vars


// prefixes
var http_prefix = 'https://'
var devPrefix = 'dev'

// resource name vars
var webAppName = '${applicationNamePrefix}-web-${uniqueString(resourceGroup().id)}'
var devWebAppName = '${devPrefix}-${webAppName}'
var functionName = '${applicationNamePrefix}-web-function-${uniqueString(resourceGroup().id)}'
var devFunctionName = '${devPrefix}-${functionName}'
var appServicePlanName = '${applicationNamePrefix}-asp-${uniqueString(resourceGroup().id)}'
var devAppServicePlanName = '${devPrefix}-${appServicePlanName}'
var logAnalyticsWorkspaceName = '${applicationNamePrefix}-la-${uniqueString(resourceGroup().id)}'
var applicationInsightsName = '${applicationNamePrefix}-ai-${uniqueString(resourceGroup().id)}'
var devApplicationInsightsName = '${devPrefix}-${applicationInsightsName}'
var applicationInsightsNameFunction = '${applicationNamePrefix}-ai-function-${uniqueString(resourceGroup().id)}'
var devApplicationInsightsNameFunction = '${devPrefix}-${applicationInsightsNameFunction}'
var keyVaultName = '${applicationNamePrefix}-kv-${uniqueString(resourceGroup().id)}'
var devKeyVaultName = '${devPrefix}-${keyVaultName}'
var storageAccountName = '${applicationNamePrefix}stor${uniqueString(resourceGroup().id)}'
var devStorageAccountName = '${devPrefix}-${storageAccountName}'
var mySQLServerName = '${applicationNamePrefix}-mysql-${uniqueString(resourceGroup().id)}'
var devMySQLServerName = '${devPrefix}-${mySQLServerName}'

// other vars
var databaseLogin = 'ghost'
var databaseName = 'ghost'
var ghostContentFileShareName = 'contentfiles'
var devGhostContentFileShareName = '${devPrefix}Contentfiles'
var ghostContentFilesMountPath = '/var/lib/ghost/content_files'
var siteUrl = (deploymentConfiguration == 'Web app with Azure Front Door') ? 'https://${frontDoorName}.azurefd.net' : 'https://${cdnEndpointName}.azureedge.net'


// TODO
// var devSiteUrl 

//Web app with Azure CDN
var cdnProfileName = '${applicationNamePrefix}-cdnp-${uniqueString(resourceGroup().id)}'
var cdnEndpointName = '${applicationNamePrefix}-cdne-${uniqueString(resourceGroup().id)}'
var cdnProfileSku = {
  name: 'Standard_Microsoft'
}

//Web app with Azure Front Door
var frontDoorName = '${applicationNamePrefix}-fd-${uniqueString(resourceGroup().id)}'
var wafPolicyName = '${applicationNamePrefix}waf${uniqueString(resourceGroup().id)}'

module logAnalyticsWorkspace './modules/logAnalyticsWorkspace.bicep' = {
  name: 'logAnalyticsWorkspaceDeploy'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    location: location
    retentionInDays: retentionInDays
  }
}

module storageAccount 'modules/storageAccount.bicep' = {
  name: 'storageAccountDeploy'
  params: {
    storageAccountName: storageAccountName
    storageAccountSku: storageAccountSku
    fileShareFolderName: ghostContentFileShareName
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    location: location
  }
}

// dev storageAccount
module devStorageAccount 'modules/storageAccount.bicep' = {
  name: '${devPrefix}storageAccountDeploy'
  params: {
    storageAccountName: devStorageAccountName
    storageAccountSku: devStorageAccountSku
    fileShareFolderName: devGhostContentFileShareName
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    location: location
  }
}

module keyVault './modules/keyVault.bicep' = {
  name: 'keyVaultDeploy'
  params: {
    keyVaultName: keyVaultName
    keyVaultSecretName: 'databasePassword'
    keyVaultSecretValue: databasePassword
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    servicePrincipalId: webApp.outputs.principalId
    location: location
  }
}

// dev keyVault
module devKeyVault './modules/keyVault.bicep' = {
  name: '${devPrefix}keyVaultDeploy'
  params: {
    keyVaultName: devKeyVaultName
    keyVaultSecretName: 'databasePassword'
    keyVaultSecretValue: databasePassword
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    servicePrincipalId: devWebApp.outputs.principalId
    location: location
  }
}

module webApp './modules/webApp.bicep' = {
  name: 'webAppDeploy'
  params: {
    webAppName: webAppName
    appServicePlanId: appServicePlan.outputs.id
    ghostContainerImage: ghostContainerName
    ghostContainerTag: ghostContainerTag
    storageAccountName: storageAccount.outputs.name
    storageAccountAccessKey: storageAccount.outputs.accessKey
    fileShareName: ghostContentFileShareName
    containerMountPath: ghostContentFilesMountPath
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    deploymentConfiguration: deploymentConfiguration
  }
}

// devWebApp
module devWebApp './modules/webApp.bicep' = {
  name: '${devPrefix}webAppDeploy'
  params: {
    webAppName: devWebAppName
    appServicePlanId: devAppServicePlan.outputs.id
    ghostContainerImage: ghostContainerName
    ghostContainerTag: 'latest'
    storageAccountName: devStorageAccount.outputs.name
    storageAccountAccessKey: devStorageAccount.outputs.accessKey
    fileShareName: devGhostContentFileShareName
    containerMountPath: ghostContentFilesMountPath
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    deploymentConfiguration: 'Web app dev'
  }
}

module function './modules/function.bicep' = {
  name: 'functionDeploy'
  params: {
    pkgURL: pkgURL
    functionName: functionName
    appServicePlanId: appServicePlan.outputs.id
    location: location
    applicationInsightsNameFunction: applicationInsightsNameFunction
    ghostApiVersion: ghostApiVersion
    ghostURL: '${http_prefix}${frontDoor.outputs.frontendEndpointHostName}'
    storageAccountAccessKey: storageAccount.outputs.accessKey
    storageAccountName: storageAccount.outputs.name
  }
}

// devFunction
module devFunction './modules/function.bicep' = {
  name: '${devPrefix}functionDeploy'
  params: {
    pkgURL: pkgURL
    functionName: devFunctionName
    appServicePlanId: devAppServicePlan.outputs.id
    location: location
    applicationInsightsNameFunction: devApplicationInsightsNameFunction
    ghostApiVersion: devGhostApiVersion
    ghostURL: 'http://test'
    storageAccountAccessKey: devStorageAccount.outputs.accessKey
    storageAccountName: devStorageAccount.outputs.name
  }
}

module webAppSettings 'modules/webAppSettings.bicep' = {
  name: 'webAppSettingsDeploy'
  params: {
    webAppName: webApp.outputs.name
    applicationInsightsConnectionString: applicationInsights.outputs.ConnectionString
    applicationInsightsInstrumentationKey: applicationInsights.outputs.InstrumentationKey
    containerRegistryUrl: containerRegistryUrl
    containerMountPath: ghostContentFilesMountPath
    databaseHostFQDN: mySQLServer.outputs.fullyQualifiedDomainName
    databaseLogin: databaseLogin
    databasePasswordSecretUri: keyVault.outputs.databasePasswordSecretUri
    databaseName: databaseName
    siteUrl: siteUrl
  }
}

// devWebAppSettings
module devWebAppSettings 'modules/webAppSettings.bicep' = {
  name: '${devPrefix}WebAppSettingsDeploy'
  params: {
    webAppName: devWebApp.outputs.name
    applicationInsightsConnectionString: devApplicationInsights.outputs.ConnectionString
    applicationInsightsInstrumentationKey: devApplicationInsights.outputs.InstrumentationKey
    containerRegistryUrl: containerRegistryUrl
    containerMountPath: ghostContentFilesMountPath
    databaseHostFQDN: devMySQLServer.outputs.fullyQualifiedDomainName
    databaseLogin: databaseLogin
    databasePasswordSecretUri: devKeyVault.outputs.databasePasswordSecretUri
    databaseName: databaseName
    siteUrl: devSiteUrl
  }
}

module appServicePlan './modules/appServicePlan.bicep' = {
  name: 'appServicePlanDeploy'
  params: {
    appServicePlanName: appServicePlanName
    appServicePlanSku: appServicePlanSku
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

// devAppServicePlan
module devAppServicePlan './modules/appServicePlan.bicep' = {
  name: '${devPrefix}appServicePlanDeploy'
  params: {
    appServicePlanName: devAppServicePlanName
    appServicePlanSku: devAppServicePlanSku
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

module applicationInsights './modules/applicationInsights.bicep' = {
  name: 'applicationInsightsDeploy'
  params: {
    applicationInsightsName: applicationInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

// devApplicationInsights
module devApplicationInsights './modules/applicationInsights.bicep' = {
  name: '${devPrefix}applicationInsightsDeploy'
  params: {
    applicationInsightsName: devApplicationInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

module mySQLServer 'modules/mySQLServer.bicep' = {
  name: 'mySQLServerDeploy'
  params: {
    administratorLogin: databaseLogin
    administratorPassword: databasePassword
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    mySQLServerName: mySQLServerName
    mySQLServerSku: mySQLServerSku
    geoRedundantBackup: geoRedundantBackup
    highAvailabilityMode: highAvailabilityMode
  }
}

// devMySQLServer
module devMySQLServer 'modules/mySQLServer.bicep' = {
  name: '${devPrefix}mySQLServerDeploy'
  params: {
    administratorLogin: databaseLogin
    administratorPassword: devDatabasePassword
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    mySQLServerName: devMySQLServerName
    mySQLServerSku: devMySQLServerSku
    geoRedundantBackup: devGeoRedundantBackup
    highAvailabilityMode: devHighAvailabilityMode
  }
}

module cdnEndpoint './modules/cdnEndpoint.bicep' = if (deploymentConfiguration == 'Web app with Azure CDN') {
  name: 'cdnEndPointDeploy'
  params: {
    cdnProfileName: cdnProfileName
    cdnProfileSku: cdnProfileSku
    cdnEndpointName: cdnEndpointName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    webAppName: webApp.name
    webAppHostName: webApp.outputs.hostName
  }
}

module frontDoor 'modules/frontDoor.bicep' = if (deploymentConfiguration == 'Web app with Azure Front Door') {
  name: 'FrontDoorDeploy'
  params: {
    frontDoorName: frontDoorName
    wafPolicyName: wafPolicyName
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    webAppName: webApp.outputs.name
  }
}

output webAppName string = webApp.outputs.name
output webAppPrincipalId string = webApp.outputs.principalId
output webAppHostName string = webApp.outputs.hostName

output devWebAppName string = devWebApp.outputs.name
output devWebAppPrincipalId string = devWebApp.outputs.principalId
output devWebAppHostName string = devWebApp.outputs.hostName

var endpointHostName = (deploymentConfiguration == 'Web app with Azure Front Door') ? frontDoor.outputs.frontendEndpointHostName : cdnEndpoint.outputs.cdnEndpointHostName

output endpointHostName string = endpointHostName

// TODO
// var endpointHostName = (deploymentConfiguration == 'Web app with Azure Front Door') ? frontDoor.outputs.frontendEndpointHostName : cdnEndpoint.outputs.cdnEndpointHostName

// output endpointHostName string = endpointHostName
