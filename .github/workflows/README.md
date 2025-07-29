# 🚀 CI/CD Pipeline - Deploy Automatizado para Azure

Este documento descreve a configuração e uso da esteira de CI/CD implementada para o projeto MongoDB-Kafka Connector, que realiza deploy automatizado dos containers Docker no Azure.

## 📋 Visão Geral

A esteira de CI/CD foi projetada para:

- ✅ **Build automatizado** das imagens Docker
- ✅ **Push para Azure Container Registry (ACR)**
- ✅ **Deploy para Azure Web App for Containers**
- ✅ **Deploy alternativo para Azure Container Instances**
- ✅ **Configuração automática de variáveis de ambiente**
- ✅ **Verificação de saúde da aplicação**
- ✅ **Suporte a múltiplos ambientes** (production, staging, development)

## 🏗️ Arquitetura da Pipeline

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub        │    │   Azure         │    │   Aplicação     │
│   Repository    │───▶│   Container     │───▶│   Azure Web App │
│                 │    │   Registry      │    │   / ACI         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
    Push/Dispatch            Build & Push             Deploy & Config
```

## 🔧 Workflows Disponíveis

### 1. Deploy para Azure Web App (`azure-deploy.yml`)

**Trigger:**
- Push na branch `main`
- Dispatch manual

**Funcionalidades:**
- Build da imagem Kafka Connect
- Push para Azure Container Registry
- Deploy para Azure Web App for Containers
- Configuração de variáveis de ambiente
- Verificação de saúde

### 2. Deploy para Azure Container Instances (`azure-container-instances.yml`)

**Trigger:**
- Dispatch manual apenas

**Funcionalidades:**
- Build da imagem Kafka Connect
- Deploy para Azure Container Instances
- Ideal para ambientes de teste/staging
- Configuração flexível de recursos

## 🔐 Configuração de Secrets

### Secrets Obrigatórios no GitHub

Configure os seguintes secrets no repositório GitHub (`Settings` → `Secrets and variables` → `Actions`):

#### Azure Container Registry (ACR)
```bash
ACR_REGISTRY=<seu-registry>.azurecr.io
ACR_USERNAME=<username-do-acr>
ACR_PASSWORD=<password-do-acr>
```

#### Azure Web App
```bash
AZURE_WEBAPP_NAME=<nome-do-web-app>
AZURE_RESOURCE_GROUP=<nome-do-resource-group>
```

#### Azure Container Instances (Opcional)
```bash
ACI_CONTAINER_GROUP_NAME=<nome-do-container-group>
```

#### Credenciais Azure
```bash
AZURE_CREDENTIALS=<json-das-credenciais-azure>
```

#### MongoDB Atlas
```bash
MONGODB_ATLAS_CONNECTION_STRING=mongodb+srv://<user>:<password>@<cluster>.mongodb.net/<database>?retryWrites=true&w=majority
```

#### Kafka (Opcional - se usando Kafka externo)
```bash
KAFKA_BOOTSTRAP_SERVERS=<kafka-broker-urls>
```

### Como Obter as Credenciais Azure

#### 1. Criar Service Principal

```bash
# Login no Azure CLI
az login

# Criar service principal
az ad sp create-for-rbac \
  --name "mongodb-kafka-cd" \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group> \
  --sdk-auth
```

O comando retornará um JSON que deve ser usado no secret `AZURE_CREDENTIALS`:

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

#### 2. Obter Credenciais do ACR

```bash
# Habilitar admin no ACR
az acr update --name <registry-name> --admin-enabled true

# Obter credenciais
az acr credential show --name <registry-name>
```

## 🌍 Configuração de Ambientes

### Production
- **Trigger**: Push automático na branch `main`
- **Deploy**: Azure Web App for Containers
- **MongoDB**: Connection string do Atlas produtivo

### Staging/Development
- **Trigger**: Dispatch manual
- **Deploy**: Azure Container Instances
- **MongoDB**: Connection string específico do ambiente

## 🚀 Como Usar

### Deploy Automático (Production)

1. Faça commit e push na branch `main`:
```bash
git add .
git commit -m "feat: nova funcionalidade"
git push origin main
```

2. A pipeline será executada automaticamente

### Deploy Manual

1. Acesse a aba `Actions` no GitHub
2. Selecione o workflow desejado
3. Clique em `Run workflow`
4. Escolha o ambiente e execute

### Monitoramento

Acompanhe o progresso através da aba `Actions` no GitHub. Cada step mostra logs detalhados.

## 📊 Verificação de Deploy

### URLs de Acesso

Após o deploy, a aplicação estará disponível em:

- **Azure Web App**: `https://<webapp-name>.azurewebsites.net:8083`
- **Azure Container Instances**: `http://<container-group-name>.<region>.azurecontainer.io:8083`

### Endpoints da API

- **Status dos Connectors**: `/connectors`
- **Health Check**: `/connector-plugins`
- **Configuração**: `/connectors/<connector-name>/config`

### Exemplo de Teste

```bash
# Verificar status da API
curl https://<sua-app>.azurewebsites.net:8083/connectors

# Listar plugins disponíveis
curl https://<sua-app>.azurewebsites.net:8083/connector-plugins
```

## 🔍 Solução de Problemas

### Build Falhando

1. **Verificar secrets**: Certifique-se que todos os secrets estão configurados
2. **Verificar ACR**: Confirmar se o registry existe e está acessível
3. **Logs**: Analisar os logs detalhados na aba Actions

### Deploy Falhando

1. **Recursos Azure**: Verificar se o Web App/ACI existe
2. **Permissões**: Confirmar se o service principal tem as permissões necessárias
3. **Quotas**: Verificar se há cota disponível na subscription

### Aplicação não Responde

1. **Aguardar**: A aplicação pode levar alguns minutos para inicializar
2. **Logs**: Verificar logs no Azure Portal
3. **Variáveis**: Confirmar se as variáveis de ambiente estão corretas

## 🛠️ Customização

### Adicionar Novos Ambientes

1. Edite o workflow YAML
2. Adicione o novo ambiente em `options`
3. Configure secrets específicos se necessário

### Modificar Configuração

1. Edite as variáveis de ambiente nos workflows
2. Ajuste os recursos (CPU/Memory) conforme necessário
3. Adicione novos steps de validação

### Integrar com Outros Serviços

1. Adicione novos jobs nos workflows
2. Configure secrets adicionais
3. Implemente health checks específicos

## 📚 Recursos Adicionais

- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)
- [Azure Web App for Containers](https://docs.microsoft.com/azure/app-service/containers/)
- [Azure Container Instances](https://docs.microsoft.com/azure/container-instances/)
- [GitHub Actions](https://docs.github.com/actions)
- [MongoDB Atlas](https://docs.atlas.mongodb.com/)

## 🤝 Contribuindo

Para melhorar a pipeline:

1. Fork o repositório
2. Crie uma branch para sua feature
3. Teste as modificações
4. Abra um Pull Request

---

**⚠️ Importante**: Nunca commite credenciais ou secrets diretamente no código. Use sempre GitHub Secrets para informações sensíveis.