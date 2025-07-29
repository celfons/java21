# 🚀 CI/CD Pipeline - Automated Deploy to Azure

This document describes the configuration and usage of the CI/CD pipeline implemented for the MongoDB-Kafka Connector project, which performs automated deployment of Docker containers to Azure.

## 📋 Overview

The CI/CD pipeline was designed to:

- ✅ **Automated build** of Docker images
- ✅ **Push to Azure Container Registry (ACR)**
- ✅ **Deploy to Azure Web App for Containers**
- ✅ **Alternative deploy to Azure Container Instances**
- ✅ **Automatic environment variable configuration**
- ✅ **Application health verification**
- ✅ **Support for multiple environments** (production, staging, development)

## 🏗️ Pipeline Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub        │    │   Azure         │    │   Application   │
│   Repository    │───▶│   Container     │───▶│   Azure Web App │
│                 │    │   Registry      │    │   / ACI         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
    Push/Dispatch            Build & Push             Deploy & Config
```

## 🔧 Available Workflows

### 1. Deploy to Azure Web App (`azure-deploy.yml`)

**Trigger:**
- Push to `main` branch
- Manual dispatch

**Features:**
- Build Kafka Connect image
- Push to Azure Container Registry
- Deploy to Azure Web App for Containers
- Environment variable configuration
- Health verification

### 2. Deploy to Azure Container Instances (`azure-container-instances.yml`)

**Trigger:**
- Manual dispatch only

**Features:**
- Build Kafka Connect image
- Deploy to Azure Container Instances
- Ideal for test/staging environments
- Flexible resource configuration

## 🔐 Secrets Configuration

### Required Secrets in GitHub

Configure the following secrets in the GitHub repository (`Settings` → `Secrets and variables` → `Actions`):

#### Azure Container Registry (ACR)
```bash
ACR_REGISTRY=<your-registry>.azurecr.io
ACR_USERNAME=<acr-username>
ACR_PASSWORD=<acr-password>
```

#### Azure Web App
```bash
AZURE_WEBAPP_NAME=<web-app-name>
AZURE_RESOURCE_GROUP=<resource-group-name>
```

#### Azure Container Instances (Optional)
```bash
ACI_CONTAINER_GROUP_NAME=<container-group-name>
```

#### Azure Credentials
```bash
AZURE_CREDENTIALS=<azure-credentials-json>
```

#### MongoDB Atlas
```bash
MONGODB_ATLAS_CONNECTION_STRING=mongodb+srv://<user>:<password>@<cluster>.mongodb.net/<database>?retryWrites=true&w=majority
```

#### Kafka (Optional - if using external Kafka)
```bash
KAFKA_BOOTSTRAP_SERVERS=<kafka-broker-urls>
```

### How to Obtain Azure Credentials

#### 1. Create Service Principal

```bash
# Login to Azure CLI
az login

# Create service principal
az ad sp create-for-rbac \
  --name "mongodb-kafka-cd" \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group> \
  --sdk-auth
```

The command will return a JSON that should be used in the `AZURE_CREDENTIALS` secret:

```json
{
  "clientId": "<client-id>",
  "clientSecret": "<client-secret>",
  "subscriptionId": "<subscription-id>",
  "tenantId": "<tenant-id>",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

#### 2. Get ACR Credentials

```bash
# Enable admin in ACR
az acr update --name <registry-name> --admin-enabled true

# Get credentials
az acr credential show --name <registry-name>
```

## 🌍 Environment Configuration

### Production
- **Trigger**: Automatic push to `main` branch
- **Deploy**: Azure Web App for Containers
- **MongoDB**: Production Atlas connection string

### Staging/Development
- **Trigger**: Manual dispatch
- **Deploy**: Azure Container Instances
- **MongoDB**: Environment-specific connection string

## 🚀 How to Use

### Automatic Deploy (Production)

1. Make commit and push to `main` branch:
```bash
git add .
git commit -m "feat: new feature"
git push origin main
```

2. The pipeline will run automatically

### Manual Deploy

1. Access the `Actions` tab in GitHub
2. Select the desired workflow
3. Click `Run workflow`
4. Choose the environment and execute

### Monitoring

Track progress through the `Actions` tab in GitHub. Each step shows detailed logs.

## 📊 Deploy Verification

### Access URLs

After deployment, the application will be available at:

- **Azure Web App**: `https://<webapp-name>.azurewebsites.net:8083`
- **Azure Container Instances**: `http://<container-group-name>.<region>.azurecontainer.io:8083`

### API Endpoints

- **Connector Status**: `/connectors`
- **Health Check**: `/connector-plugins`
- **Configuration**: `/connectors/<connector-name>/config`

### Testing Example

```bash
# Check API status
curl https://<your-app>.azurewebsites.net:8083/connectors

# List available plugins
curl https://<your-app>.azurewebsites.net:8083/connector-plugins
```

## 🔍 Troubleshooting

### Build Failing

1. **Check secrets**: Make sure all secrets are configured
2. **Check ACR**: Confirm that the registry exists and is accessible
3. **Logs**: Analyze detailed logs in the Actions tab

### Deploy Failing

1. **Azure Resources**: Check if Web App/ACI exists
2. **Permissions**: Confirm that the service principal has the necessary permissions
3. **Quotas**: Check if there's available quota in the subscription

### Application Not Responding

1. **Wait**: The application may take a few minutes to initialize
2. **Logs**: Check logs in Azure Portal
3. **Variables**: Confirm that environment variables are correct

## 🛠️ Customization

### Add New Environments

1. Edit the workflow YAML
2. Add the new environment in `options`
3. Configure environment-specific secrets if needed

### Modify Configuration

1. Edit environment variables in workflows
2. Adjust resources (CPU/Memory) as needed
3. Add new validation steps

### Integrate with Other Services

1. Add new jobs in workflows
2. Configure additional secrets
3. Implement specific health checks

## 📚 Additional Resources

- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)
- [Azure Web App for Containers](https://docs.microsoft.com/azure/app-service/containers/)
- [Azure Container Instances](https://docs.microsoft.com/azure/container-instances/)
- [GitHub Actions](https://docs.github.com/actions)
- [MongoDB Atlas](https://docs.atlas.mongodb.com/)

## 🤝 Contributing

To improve the pipeline:

1. Fork the repository
2. Create a branch for your feature
3. Test the modifications
4. Open a Pull Request

---

**⚠️ Important**: Never commit credentials or secrets directly in code. Always use GitHub Secrets for sensitive information.