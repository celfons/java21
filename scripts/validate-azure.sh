#!/bin/bash

# Script de validação para configuração Azure
# Verifica se todos os componentes necessários estão configurados

set -e

echo "🔍 VALIDAÇÃO DE CONFIGURAÇÃO AZURE"
echo "=================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para verificar comando
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 está instalado"
        return 0
    else
        echo -e "${RED}✗${NC} $1 não está instalado"
        return 1
    fi
}

# Função para verificar arquivo
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 existe"
        return 0
    else
        echo -e "${RED}✗${NC} $1 não existe"
        return 1
    fi
}

# Função para verificar variável de ambiente
check_env_var() {
    if [ ! -z "${!1}" ]; then
        echo -e "${GREEN}✓${NC} $1 está definida"
        return 0
    else
        echo -e "${RED}✗${NC} $1 não está definida"
        return 1
    fi
}

echo "📋 VERIFICANDO DEPENDÊNCIAS LOCAIS:"
echo "-----------------------------------"

# Verificar dependências
DEPS_OK=true
check_command "docker" || DEPS_OK=false
check_command "az" || echo -e "${YELLOW}⚠${NC}  Azure CLI não instalada (opcional para testes locais)"

echo ""
echo "📁 VERIFICANDO ARQUIVOS NECESSÁRIOS:"
echo "-----------------------------------"

# Verificar arquivos
FILES_OK=true
check_file "Dockerfile" || FILES_OK=false
check_file ".github/workflows/azure-deploy.yml" || FILES_OK=false
check_file ".github/workflows/azure-container-instances.yml" || FILES_OK=false
check_file "docker-compose.azure.yml" || FILES_OK=false
check_file ".env.azure.example" || FILES_OK=false

echo ""
echo "🔧 VERIFICANDO CONFIGURAÇÃO AZURE LOCAL:"
echo "---------------------------------------"

# Verificar se arquivo .env.azure existe
if [ -f ".env.azure" ]; then
    echo -e "${GREEN}✓${NC} .env.azure existe"
    
    # Carregar variáveis do .env.azure
    set -a
    source .env.azure
    set +a
    
    # Verificar variáveis essenciais
    ENV_OK=true
    check_env_var "ACR_REGISTRY" || ENV_OK=false
    check_env_var "ACR_USERNAME" || ENV_OK=false
    check_env_var "ACR_PASSWORD" || ENV_OK=false
    check_env_var "AZURE_WEBAPP_NAME" || ENV_OK=false
    check_env_var "AZURE_RESOURCE_GROUP" || ENV_OK=false
    check_env_var "MONGODB_ATLAS_CONNECTION_STRING" || ENV_OK=false
    
else
    echo -e "${YELLOW}⚠${NC}  .env.azure não existe (opcional para testes locais)"
    echo "    Execute: make azure-env para criar o template"
    ENV_OK=false
fi

echo ""
echo "🎯 VERIFICANDO GITHUB ACTIONS:"
echo "-----------------------------"

# Verificar se workflows são válidos
if [ -f ".github/workflows/azure-deploy.yml" ]; then
    echo -e "${GREEN}✓${NC} Workflow principal configurado"
fi

if [ -f ".github/workflows/azure-container-instances.yml" ]; then
    echo -e "${GREEN}✓${NC} Workflow ACI configurado"
fi

echo ""
echo "📚 SECRETS NECESSÁRIOS NO GITHUB:"
echo "--------------------------------"
echo "  • ACR_REGISTRY"
echo "  • ACR_USERNAME" 
echo "  • ACR_PASSWORD"
echo "  • AZURE_CREDENTIALS"
echo "  • AZURE_WEBAPP_NAME"
echo "  • AZURE_RESOURCE_GROUP"
echo "  • MONGODB_ATLAS_CONNECTION_STRING"
echo ""
echo "🔗 Configurar em: Settings → Secrets and variables → Actions"

echo ""
echo "📊 RESULTADO DA VALIDAÇÃO:"
echo "========================="

if [ "$DEPS_OK" = true ] && [ "$FILES_OK" = true ]; then
    echo -e "${GREEN}✅ CONFIGURAÇÃO OK${NC} - Pronto para deploy no Azure!"
    echo ""
    echo "🚀 PRÓXIMOS PASSOS:"
    echo "  1. Configure os secrets no GitHub"
    echo "  2. Faça push na branch main para deploy automático"
    echo "  3. Ou use dispatch manual para outros ambientes"
    
    if [ "$ENV_OK" = true ]; then
        echo ""
        echo "🧪 TESTE LOCAL:"
        echo "  make azure-test-local  # Testar configuração localmente"
    fi
    
    exit 0
else
    echo -e "${RED}❌ CONFIGURAÇÃO INCOMPLETA${NC}"
    echo ""
    echo "🔧 AÇÕES NECESSÁRIAS:"
    
    if [ "$DEPS_OK" = false ]; then
        echo "  • Instalar dependências faltantes"
    fi
    
    if [ "$FILES_OK" = false ]; then
        echo "  • Verificar arquivos de configuração"
    fi
    
    echo ""
    echo "📖 Consulte a documentação: .github/workflows/README.md"
    exit 1
fi