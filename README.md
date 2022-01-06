# Application Modernization with App Services and well-architected best practices on Azure

This is not just another Quickstart template to spin up App Server nor demonstrate vnet integration. It aims to provide a full accerelator template for App Sevices based application modernization which meets the well architected framework guidance of Azure.

## Architecture 
![Architecture diagram](https://raw.githubusercontent.com/KietNhiTran/appmodernized-with-appservice-well-architected-accelerator/main/images/appmodernized-with-appservice-well-architected-accelerator.jpg)

## How to deploy
The project used bicep as main language for deployment. 

To learn about bicep, please visit [bicep documentation.](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)

```console
az deployment sub create --name <name your deployment if you like> --template-file main.bicep --location <location of this deployment> --parameters resourceGroupName='<To be created resource group name>' location='<Where to deploy this accelerator>' sqlServerAdmin='<SQL server admin username>' sqlServerPassword='<sql server admin password>' enableZoneRedundant='<true|false>'
```

Example deployement:
```console
az deployment sub create --name prodeatusdeployment --template-file main.bicep --location eastus --parameters resourceGroupName='prodtemplate03-rg' location='eastus' sqlServerAdmin='sqladmin' sqlServerPassword='Abcd12345678' enableZoneRedundant='true'
```

## Features in this accelerator
- Web application inbound traffic is protected via [Application Gateway web firewall OWASP 3.2 prebuilt rule set](https://docs.microsoft.com/en-us/azure/web-application-firewall/ag/application-gateway-crs-rulegroups-rules?tabs=owasp32), SSL termination and using https.
- App Services is provisioned with following best practices:
    - [zone redundance is applied which helps overcome datacenter failured ](https://docs.microsoft.com/en-us/azure/app-service/how-to-zone-redundancy)
    - [Health check endpoint is configured](https://docs.microsoft.com/en-us/azure/app-service/monitor-instances-health-check)
    - [Access restriction is turned and only allow traffice from Application Gateway](https://docs.microsoft.com/en-us/azure/app-service/networking/app-gateway-with-service-endpoints#integration-with-app-service-multi-tenant)
    - Using keyvault to store sensitive configuration
    - Implement secure access to backend database and keyvault via [regional VNet integration and private endpoints](https://docs.microsoft.com/en-us/azure/app-service/configure-vnet-integration-enable)
    - [Performance monitoring via Application Insight](https://docs.microsoft.com/en-us/azure/app-service/monitor-app-service)
- The accelerator also demonstrate how to upload a self-signed certificate to key vault during deployment and how to refer to secret in keyvault using deployment template
- The database & key vault are blocked internet access and only accessible via private endpoint.
- All resources are turn on diagnostics setting to centrally connect platform log and metrics to log analytics workspace.
- Network security group flow log is created under region network watcher and turn on traffice analysis through log analytics workspace.
- Using managed identity to grant access and role assignment.

## Planned features
- Prebiult dashboard with critical metrics to the app and database.
- Apply more security best practices like: DDoS, defenders.
- CI/CD to demo a IaC deployment vis github action.
- you name it via 'issue' :-)

# Contribution Guide
1. Fork this repo
2. Clone the repor locally
3. Create feature branch
4. Commit your change to feature branch
5. Push your change
6. Create a pull request to this repo

# Feedback
Feel free to request new feature and post your idea in issue list. 

