# Plano de Estudos Avançado - Certificação Azure AZ-104 (Microsoft Azure Administrator)

Este documento apresenta um plano de estudos estruturado e abrangente para a certificação Microsoft Azure Administrator (AZ-104), incluindo cronograma detalhado, recursos recomendados e laboratórios práticos essenciais.

## Índice

1. [Informações Gerais da Certificação](#1-informações-gerais-da-certificação)
2. [Domínios Principais da Certificação](#2-domínios-principais-da-certificação)
3. [Cronograma de Estudos Sugerido](#3-cronograma-de-estudos-sugerido)
4. [Recursos de Estudo Recomendados](#4-recursos-de-estudo-recomendados)
5. [Laboratórios Práticos Essenciais](#5-laboratórios-práticos-essenciais)
6. [Dicas de Preparação para o Exame](#6-dicas-de-preparação-para-o-exame)

---

## 1. Informações Gerais da Certificação

### Visão Geral da Certificação AZ-104

A certificação **Microsoft Azure Administrator (AZ-104)** valida as habilidades e conhecimentos necessários para implementar, gerenciar e monitorar ambientes Microsoft Azure. Esta certificação é ideal para profissionais que desejam demonstrar expertise em administração de infraestrutura Azure.

**Público-Alvo:**
- Administradores de sistemas
- Engenheiros de infraestrutura em nuvem
- Profissionais de TI que trabalham com Azure
- Especialistas em DevOps

### Pré-requisitos e Conhecimentos Necessários

**Conhecimentos Fundamentais:**
- Conceitos básicos de computação em nuvem
- Experiência com sistemas operacionais Windows e Linux
- Conhecimentos de rede (TCP/IP, DNS, VPN)
- Conceitos de virtualização
- Noções básicas de PowerShell e Azure CLI

**Experiência Recomendada:**
- Mínimo de 6 meses de experiência prática com Azure
- Experiência em administração de sistemas
- Conhecimento básico de conceitos de segurança

**Certificações Preparatórias (Recomendadas):**
- AZ-900: Microsoft Azure Fundamentals
- Experiência com AZ-104 fundamentals ou cursos introdutórios

### Formato do Exame e Critérios de Aprovação

**Detalhes do Exame:**
- **Código:** AZ-104
- **Duração:** 120 minutos
- **Número de Questões:** 40-60 questões
- **Pontuação Mínima:** 700 pontos (escala de 1-1000)
- **Formato:** Múltipla escolha, arrastar e soltar, estudos de caso
- **Idiomas Disponíveis:** Português, Inglês, e outros
- **Validade:** 2 anos

**Tipos de Questões:**
- Múltipla escolha simples
- Múltipla escolha múltipla
- Arrastar e soltar
- Lista de seleção
- Estudos de caso com cenários práticos
- Questões baseadas em simulação (hands-on)

---

## 2. Domínios Principais da Certificação

### Gerenciar Identidades e Governança do Azure (15-20%)

#### Azure Active Directory (Azure AD)

**Tópicos Essenciais:**
- Criação e configuração de tenants do Azure AD
- Gerenciamento de usuários e grupos
- Configuração de propriedades de usuário e grupo
- Criação de unidades administrativas
- Configuração de dispositivos no Azure AD

**Conceitos Importantes:**
- **Tenant:** Instância dedicada do Azure AD
- **Diretório:** Contém usuários, grupos e aplicações
- **Domínio Personalizado:** Configuração de domínios próprios
- **Sincronização Híbrida:** Azure AD Connect

#### Usuários e Grupos

**Gerenciamento de Usuários:**
- Criação e exclusão de usuários
- Configuração de perfis de usuário
- Redefinição de senhas
- Gerenciamento de licenças
- Configuração de acesso de usuários externos (B2B)

**Gerenciamento de Grupos:**
- Grupos de segurança vs. grupos do Microsoft 365
- Associação dinâmica de grupos
- Grupos aninhados
- Atribuição de licenças baseada em grupo

#### Controle de Acesso Baseado em Função (RBAC)

**Componentes do RBAC:**
- **Entidades de Segurança:** Usuários, grupos, service principals
- **Definições de Função:** Conjuntos de permissões
- **Escopo:** Onde as permissões se aplicam
- **Atribuições:** Vinculação entre entidade, função e escopo

**Funções Integradas Importantes:**
- Owner (Proprietário)
- Contributor (Colaborador)
- Reader (Leitor)
- User Access Administrator
- Funções específicas de serviços

**Funções Personalizadas:**
- Criação de funções customizadas
- Definição de ações e DataActions
- Escopo de atribuição

#### Azure Policy

**Conceitos Fundamentais:**
- Definições de política
- Iniciativas de política
- Atribuições de política
- Efeitos de política (Deny, Audit, Append, etc.)

**Implementação:**
- Criação de políticas personalizadas
- Avaliação de conformidade
- Remediação de recursos não conformes
- Governança e compliance

#### Gerenciamento de Recursos e Tags

**Organização de Recursos:**
- Grupos de recursos
- Hierarquia de gerenciamento
- Subscrições
- Grupos de gerenciamento

**Sistema de Tags:**
- Estratégias de marcação
- Aplicação de tags obrigatórias
- Políticas de tags
- Relatórios baseados em tags

### Implementar e Gerenciar Armazenamento (15-20%)

#### Contas de Armazenamento

**Tipos de Conta:**
- General Purpose v2 (StorageV2)
- General Purpose v1 (Storage)
- Blob Storage
- Premium Storage

**Configurações:**
- Performance tiers (Standard/Premium)
- Access tiers (Hot, Cool, Archive)
- Replication options (LRS, ZRS, GRS, RA-GRS)
- Secure transfer required
- Networking e firewall rules

#### Blobs, Arquivos, Filas e Tabelas

**Azure Blob Storage:**
- Container management
- Blob types (Block, Append, Page)
- Access tiers e lifecycle management
- Blob indexing e metadata

**Azure Files:**
- File shares
- SMB e NFS protocols
- Azure File Sync
- Backup de file shares

**Queue Storage:**
- Mensageria assíncrona
- Queue operations
- Poison message handling

**Table Storage:**
- NoSQL data store
- Entities e properties
- Partitioning strategies

#### Backup e Recuperação

**Azure Backup:**
- Recovery Services Vault
- Backup policies
- VM backup
- File/folder backup
- SQL database backup

**Disaster Recovery:**
- Azure Site Recovery
- Replication scenarios
- Failover e failback procedures
- Recovery plans

#### Azure File Sync

**Componentes:**
- Storage Sync Service
- Sync Group
- Cloud Endpoint
- Server Endpoint

**Funcionalidades:**
- Cloud tiering
- Offline data transfer
- Multi-site sync

#### Gerenciamento de Dados

**Data Movement:**
- AzCopy
- Azure Data Factory
- Import/Export Service
- Azure Data Box

**Data Security:**
- Encryption at rest
- Encryption in transit
- Shared Access Signatures (SAS)
- Storage Service Encryption

### Implantar e Gerenciar Recursos de Computação do Azure (20-25%)

#### Máquinas Virtuais (VMs)

**Criação e Configuração:**
- VM sizes e families
- Operating systems (Windows/Linux)
- Availability sets e zones
- VM scale sets
- Custom images e galleries

**Gerenciamento:**
- VM extensions
- Run Command
- Serial console access
- Boot diagnostics
- VM monitoring

**Networking:**
- Network interfaces
- Public e private IP addresses
- Network security groups
- Load balancing

#### Azure Container Instances

**Conceitos:**
- Container groups
- Multi-container deployments
- Resource allocation
- Networking configuration

**Cenários de Uso:**
- Batch jobs
- CI/CD agents
- Development environments

#### Azure Kubernetes Service (AKS)

**Cluster Management:**
- Node pools
- Cluster autoscaling
- Cluster upgrades
- RBAC integration

**Networking:**
- Service types
- Ingress controllers
- Network policies
- Azure CNI vs Kubenet

#### Azure App Service

**Web Apps:**
- Deployment slots
- Application settings
- Connection strings
- Custom domains e SSL

**Service Plans:**
- Pricing tiers
- Scaling options (manual/auto)
- Operating system selection

**Advanced Features:**
- WebJobs
- Logic Apps
- Function Apps

#### Automação e Scripting

**Azure PowerShell:**
- Cmdlets essenciais
- Scripts de automação
- Módulos Az

**Azure CLI:**
- Comandos básicos
- Script automation
- JSON output manipulation

**Azure Resource Manager (ARM):**
- Templates
- Template functions
- Linked templates
- Template deployment

### Configurar e Gerenciar Redes Virtuais (25-30%)

#### Redes Virtuais e Sub-redes

**Virtual Network (VNet):**
- Address space planning
- Subnet design
- System routes
- User-defined routes (UDR)

**Conectividade:**
- VNet peering
- Service endpoints
- Private endpoints
- NAT Gateway

#### Grupos de Segurança de Rede (NSGs)

**Configuração:**
- Inbound e outbound rules
- Service tags
- Application security groups
- NSG flow logs

**Best Practices:**
- Rule priority
- Default rules
- Security rule evaluation

#### Azure Load Balancer

**Tipos:**
- Basic vs Standard SKU
- Internal vs External
- Regional vs Global

**Configuração:**
- Frontend IP configuration
- Backend pools
- Health probes
- Load balancing rules
- Inbound NAT rules

#### Azure Application Gateway

**Funcionalidades:**
- Layer 7 load balancing
- SSL termination
- Cookie-based session affinity
- URL-based routing
- Multi-site hosting

**Web Application Firewall (WAF):**
- OWASP core rule sets
- Custom rules
- Exclusion lists

#### VPN Gateway e ExpressRoute

**VPN Gateway:**
- Site-to-Site VPN
- Point-to-Site VPN
- VNet-to-VNet connections
- BGP support

**ExpressRoute:**
- Private connectivity
- Circuit provisioning
- Peering configurations
- ExpressRoute Global Reach

#### DNS do Azure

**Public DNS:**
- Zone management
- Record types (A, AAAA, CNAME, MX, etc.)
- Alias records
- DNS delegation

**Private DNS:**
- Private zones
- Auto-registration
- Virtual network links

### Monitorar e Fazer Backup de Recursos do Azure (10-15%)

#### Azure Monitor

**Componentes:**
- Metrics
- Logs (Log Analytics)
- Application Insights
- Network Watcher

**Data Collection:**
- Diagnostic settings
- Agents (Log Analytics, Dependency)
- Custom metrics e logs

#### Log Analytics

**Workspace Management:**
- Data retention
- Access control
- Data export

**Kusto Query Language (KQL):**
- Basic queries
- Advanced filtering
- Aggregation functions
- Visualization

#### Azure Backup

**Scenarios:**
- VM backup
- SQL Server backup
- File share backup
- On-premises backup

**Advanced Features:**
- Cross-region restore
- Backup policies
- Retention policies
- Backup reports

#### Azure Site Recovery

**Disaster Recovery:**
- Azure to Azure replication
- On-premises to Azure
- Recovery plans
- Test failover

#### Alertas e Métricas

**Alert Rules:**
- Metric alerts
- Log alerts
- Activity log alerts
- Smart detection

**Action Groups:**
- Email notifications
- SMS alerts
- Webhook actions
- Logic Apps integration

---

## 3. Cronograma de Estudos Sugerido

### Plano de 12 Semanas (Recomendado)

#### Semanas 1-2: Fundamentos e Identidades (15-20 horas/semana)
**Semana 1:**
- Azure fundamentals review
- Azure AD concepts
- User e group management
- Hands-on: Criar tenant, usuários e grupos

**Semana 2:**
- RBAC implementation
- Azure Policy basics
- Resource organization
- Hands-on: Configurar RBAC e policies

#### Semanas 3-4: Armazenamento (15-20 horas/semana)
**Semana 3:**
- Storage accounts e types
- Blob storage configuration
- Azure Files setup
- Hands-on: Configurar diferentes tipos de storage

**Semana 4:**
- Backup e recovery
- Azure File Sync
- Data movement tools
- Hands-on: Implementar backup e sync

#### Semanas 5-7: Computação (20-25 horas/semana)
**Semana 5:**
- Virtual machines
- VM extensions e management
- Custom images
- Hands-on: Deploy e gerenciar VMs

**Semana 6:**
- Container services (ACI, AKS)
- App Service configuration
- Scaling strategies
- Hands-on: Deploy containers e web apps

**Semana 7:**
- Automation com PowerShell/CLI
- ARM templates
- DevOps integration
- Hands-on: Automação e templates

#### Semanas 8-10: Networking (20-25 horas/semana)
**Semana 8:**
- Virtual networks e subnets
- NSGs e security rules
- VNet peering
- Hands-on: Configurar redes complexas

**Semana 9:**
- Load balancers e gateways
- Application Gateway e WAF
- Traffic routing
- Hands-on: Implementar load balancing

**Semana 10:**
- VPN e ExpressRoute
- DNS configuration
- Hybrid connectivity
- Hands-on: Configurar conectividade híbrida

#### Semanas 11-12: Monitoramento e Revisão (15-20 horas/semana)
**Semana 11:**
- Azure Monitor setup
- Log Analytics e KQL
- Alerting strategies
- Hands-on: Implementar monitoramento completo

**Semana 12:**
- Revisão geral
- Practice exams
- Weak areas focus
- Final preparation

### Plano de 8 Semanas (Intensivo)

#### Semanas 1-2: Identidades + Armazenamento (25-30 horas/semana)
**Combinar conteúdos:**
- Azure AD e RBAC
- Storage accounts e backup
- Labs intensivos

#### Semanas 3-4: Computação (25-30 horas/semana)
**Foco em:**
- VMs e containers
- App Services
- Automation

#### Semanas 5-6: Networking (25-30 horas/semana)
**Concentrar em:**
- VNets e conectividade
- Load balancing
- Security

#### Semanas 7-8: Monitoramento + Revisão (20-25 horas/semana)
**Finalização:**
- Monitoring setup
- Practice exams
- Final review

### Distribuição de Tempo por Domínio

| Domínio | Porcentagem do Exame | Tempo de Estudo Sugerido | Prioridade |
|---------|---------------------|-------------------------|------------|
| Redes Virtuais | 25-30% | 30% do tempo total | Alta |
| Computação | 20-25% | 25% do tempo total | Alta |
| Identidades e Governança | 15-20% | 20% do tempo total | Média |
| Armazenamento | 15-20% | 15% do tempo total | Média |
| Monitoramento | 10-15% | 10% do tempo total | Baixa |

### Marcos e Checkpoints de Progresso

**Checkpoint 1 (Semana 2):**
- ✅ Configurar tenant Azure AD completo
- ✅ Implementar RBAC em cenário real
- ✅ Criar políticas de governança

**Checkpoint 2 (Semana 4):**
- ✅ Configurar storage accounts com alta disponibilidade
- ✅ Implementar backup automatizado
- ✅ Configurar File Sync

**Checkpoint 3 (Semana 7):**
- ✅ Deploy de aplicação multi-tier
- ✅ Configurar autoscaling
- ✅ Implementar CI/CD pipeline

**Checkpoint 4 (Semana 10):**
- ✅ Rede complexa com múltiplas VNets
- ✅ Conectividade híbrida funcional
- ✅ Load balancing configurado

**Checkpoint Final (Semana 11):**
- ✅ Monitoramento end-to-end
- ✅ Practice exam score > 80%
- ✅ Todos os labs concluídos

---

## 4. Recursos de Estudo Recomendados

### Documentação Oficial da Microsoft

**Links Essenciais:**
- [Azure Documentation](https://docs.microsoft.com/azure/)
- [AZ-104 Exam Guide](https://docs.microsoft.com/learn/certifications/exams/az-104)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)
- [Azure Best Practices](https://docs.microsoft.com/azure/architecture/best-practices/)

**Recursos Específicos:**
- Azure Active Directory documentation
- Virtual Machines documentation
- Virtual Network documentation
- Storage Accounts documentation
- Azure Monitor documentation

### Microsoft Learn (Módulos Específicos)

**Learning Paths Obrigatórios:**

1. **Prerequisites for Azure administrators**
   - Introduction to Azure fundamentals
   - Manage services with the Azure portal

2. **Manage identity and access in Azure Active Directory**
   - Secure Azure Active Directory users with Multi-Factor Authentication
   - Manage users and groups in Azure Active Directory

3. **Implement and manage storage in Azure**
   - Create an Azure Storage account
   - Control access to Azure Storage with shared access signatures

4. **Deploy and manage Azure compute resources**
   - Manage virtual machines with the Azure CLI
   - Create a Windows virtual machine in Azure

5. **Configure and manage virtual networks for Azure administrators**
   - Introduction to Azure Virtual Networks
   - Design an IP addressing schema for your Azure deployment

6. **Monitor and back up Azure resources**
   - Monitor your Azure virtual machines with Azure Monitor
   - Back up your virtual machines

### Laboratórios Práticos

**Microsoft Learn Labs:**
- Azure portal familiarization
- PowerShell e CLI hands-on
- Resource deployment scenarios

**Third-Party Labs:**
- A Cloud Guru hands-on labs
- Linux Academy Azure labs
- Pluralsight interactive courses

### Simulados e Exames Práticos

**Plataformas Recomendadas:**

1. **MeasureUp**
   - Simulados oficiais Microsoft
   - Explicações detalhadas
   - Performance analytics

2. **Whizlabs**
   - Multiple practice tests
   - Detailed explanations
   - Mobile app available

3. **Tutorials Dojo**
   - Comprehensive practice exams
   - Study guide included
   - Timed mode e review mode

4. **ExamTopics**
   - Community-driven questions
   - Discussion forums
   - Free e premium options

### Livros e Cursos Recomendados

**Livros:**

1. **"Exam Ref AZ-104 Microsoft Azure Administrator" - Microsoft Press**
   - Autor: Pearson Education
   - Cobertura oficial do exame
   - Scenarios e practice questions

2. **"Azure for Architects" - Packt Publishing**
   - Advanced concepts
   - Real-world scenarios
   - Best practices

**Cursos Online:**

1. **Pluralsight**
   - "Microsoft Azure Administrator (AZ-104)" path
   - Interactive exercises
   - Skill assessments

2. **A Cloud Guru**
   - Comprehensive AZ-104 course
   - Hands-on labs included
   - Community support

3. **Linux Academy (now A Cloud Guru)**
   - Azure Administrator path
   - Real-world projects
   - Certification prep

4. **Udemy**
   - Scott Duffy's AZ-104 course
   - Skylines Academy courses
   - Practice tests included

### Comunidades e Fóruns

**Plataformas de Discussão:**
- Reddit r/Azure
- Microsoft Tech Community
- Stack Overflow Azure tags
- LinkedIn Azure groups

**Discord/Slack Communities:**
- Azure community Discord
- DevOps community Slack
- Cloud study groups

---

## 5. Laboratórios Práticos Essenciais

### Laboratórios por Domínio

#### Identidades e Governança

**Lab 1: Configuração Completa do Azure AD**
- Criar tenant personalizado
- Configurar domínio customizado
- Criar estrutura organizacional de usuários e grupos
- Implementar grupo dinâmico
- Configurar B2B collaboration

**Lab 2: Implementação de RBAC Avançado**
- Criar funções personalizadas
- Configurar atribuições em diferentes escopos
- Implementar Privileged Identity Management (PIM)
- Auditoria de permissões

**Lab 3: Azure Policy e Governança**
- Criar políticas personalizadas
- Implementar initiative definitions
- Configurar compliance dashboard
- Remediação automática

#### Armazenamento

**Lab 4: Storage Account Multi-Purpose**
- Configurar diferentes performance tiers
- Implementar lifecycle management
- Configurar access tiers automáticos
- Setup de cross-region replication

**Lab 5: Backup e Disaster Recovery**
- Configurar Azure Backup para VMs
- Implementar cross-region backup
- Configurar Azure Site Recovery
- Testar failover scenarios

**Lab 6: Azure Files e File Sync**
- Configurar Azure File Shares
- Implementar Azure File Sync
- Configurar cloud tiering
- Setup offline data transfer

#### Computação

**Lab 7: VM Deployment Avançado**
- Deploy usando ARM templates
- Configurar VM Scale Sets
- Implementar custom images
- Configurar VM extensions

**Lab 8: Container Orchestration**
- Deploy de AKS cluster
- Configurar autoscaling
- Implementar ingress controller
- Deploy de aplicação multi-container

**Lab 9: App Service com DevOps**
- Configurar deployment slots
- Implementar auto-scaling
- Setup de CI/CD pipeline
- Configurar Application Insights

#### Networking

**Lab 10: Network Architecture Complexa**
- Criar hub-and-spoke topology
- Configurar VNet peering
- Implementar user-defined routes
- Setup de Network Watcher

**Lab 11: Load Balancing e High Availability**
- Configurar Azure Load Balancer
- Setup de Application Gateway com WAF
- Implementar Traffic Manager
- Configurar health probes

**Lab 12: Conectividade Híbrida**
- Configurar Site-to-Site VPN
- Setup de ExpressRoute (simulado)
- Implementar Point-to-Site VPN
- Configurar hybrid DNS

#### Monitoramento

**Lab 13: Monitoring End-to-End**
- Configurar Azure Monitor workspace
- Implementar custom metrics
- Criar dashboards personalizados
- Setup de alerting strategy

**Lab 14: Log Analytics e KQL**
- Configurar data collection
- Criar queries KQL avançadas
- Implementar log-based alerts
- Setup de automated responses

### Cenários Práticos de Implementação

#### Cenário 1: Empresa Multi-Regional
**Objetivo:** Implementar infraestrutura para empresa com escritórios em múltiplas regiões

**Componentes:**
- Multi-region VNet setup
- Cross-region backup
- Global load balancing
- Centralized monitoring

**Deliverables:**
- Network diagram
- Security implementation
- Disaster recovery plan
- Cost optimization report

#### Cenário 2: Migration On-Premises para Azure
**Objetivo:** Migrar aplicação legacy para Azure

**Fases:**
1. Assessment e planning
2. Network connectivity
3. VM migration
4. Data migration
5. DNS cutover
6. Monitoring setup

**Deliverables:**
- Migration checklist
- Testing procedures
- Rollback plan
- Performance benchmarks

#### Cenário 3: DevOps Pipeline Completo
**Objetivo:** Implementar CI/CD para aplicação web

**Componentes:**
- Source control integration
- Build automation
- Deployment automation
- Environment management
- Monitoring e logging

### Troubleshooting Comum

#### Problemas de Rede
- **Conectividade entre VNets:** Verificar peering e routes
- **NSG blocking traffic:** Análise de flow logs
- **DNS resolution issues:** Configuração de private DNS

#### Problemas de VM
- **Boot failures:** Serial console e boot diagnostics
- **Performance issues:** VM sizing e monitoring
- **Extension failures:** Log analysis e dependencies

#### Problemas de Storage
- **Access denied errors:** SAS tokens e permissions
- **Replication failures:** Network connectivity
- **Backup failures:** VM agent e policies

#### Problemas de Identidade
- **Sign-in issues:** Conditional access policies
- **Permission errors:** RBAC assignments
- **Sync problems:** Azure AD Connect configuration

---

## 6. Dicas de Preparação para o Exame

### Estratégias de Estudo

#### Cronograma de Estudos Eficiente

**Distribuição Semanal:**
- **Segunda a Sexta:** 2-3 horas de estudo por dia
- **Fins de Semana:** 4-6 horas de labs práticos
- **Total Semanal:** 15-25 horas

**Método Pomodoro Adaptado:**
- 45 minutos de estudo teórico
- 15 minutos de pausa
- 2 horas de laboratório prático
- 30 minutos de pausa

#### Técnicas de Retenção

**Active Recall:**
- Criar flashcards para conceitos importantes
- Explicar conceitos em voz alta
- Ensinar conteúdo para outros

**Spaced Repetition:**
- Revisão após 1 dia
- Revisão após 3 dias
- Revisão após 1 semana
- Revisão após 2 semanas

**Mind Mapping:**
- Criar mapas mentais para cada domínio
- Conectar conceitos relacionados
- Usar cores e símbolos visuais

### Gestão de Tempo Durante o Exame

#### Estratégia de Tempo

**Divisão por Tipo de Questão:**
- **Múltipla escolha simples:** 1-2 minutos
- **Múltipla escolha múltipla:** 2-3 minutos
- **Drag and drop:** 2-4 minutos
- **Case studies:** 10-15 minutos

**Cronograma Sugerido:**
- **Primeiros 15 minutos:** Leitura rápida de todas as questões
- **90 minutos:** Resolução das questões
- **15 minutos finais:** Revisão e verificação

#### Técnicas Durante o Exame

**Leitura de Questões:**
- Ler a pergunta duas vezes
- Identificar palavras-chave
- Eliminar opções obviamente incorretas
- Usar processo de eliminação

**Gestão de Ansiedade:**
- Respiração profunda entre questões
- Pular questões difíceis inicialmente
- Manter confiança nas respostas conhecidas

### Tipos de Questões Esperadas

#### Questões Baseadas em Cenários

**Exemplo de Estrutura:**
```
Cenário: Uma empresa precisa implementar uma solução de backup 
que atenda aos seguintes requisitos:
- Backup diário automatizado
- Retenção de 30 dias
- Recovery point objetivo (RPO) de 4 horas
- Custo otimizado

Pergunta: Qual configuração de Azure Backup atende melhor aos requisitos?

A) Standard backup policy com daily backup
B) Enhanced backup policy com 4-hour backup
C) Custom backup policy com specific retention
D) Geo-redundant backup with instant restore
```

#### Questões de Troubleshooting

**Formato Comum:**
- Descrição do problema
- Logs ou error messages
- Múltiplas soluções possíveis
- Escolha da melhor solução

#### Questões de Configuração

**Elementos Avaliados:**
- Seleção de SKUs apropriados
- Configuração de networking
- Aplicação de security best practices
- Implementação de high availability

### Recursos para Revisão Final

#### Semana Final de Preparação

**Dias 1-3: Revisão Intensiva**
- Review de todos os domínios
- Flashcards e mind maps
- Practice exams diários

**Dias 4-5: Laboratórios de Revisão**
- Refazer labs mais complexos
- Resolver cenários de troubleshooting
- Revisar conceitos com mais dificuldade

**Dias 6-7: Descanso e Confiança**
- Revisão leve
- Practice exam final
- Descanso mental

#### Checklist de Preparação Final

**Conhecimento Técnico:**
- [ ] Consegue explicar todos os serviços principais
- [ ] Compreende cenários de uso de cada serviço
- [ ] Sabe troubleshoot problemas comuns
- [ ] Domina PowerShell/CLI básico

**Prática:**
- [ ] Completou todos os labs essenciais
- [ ] Practice exam score consistente > 85%
- [ ] Consegue deploy recursos sem consultar documentação
- [ ] Compreende billing e cost optimization

**Preparação Logística:**
- [ ] Local do exame confirmado (ou setup online)
- [ ] Documentos de identificação válidos
- [ ] Computador testado (para online exams)
- [ ] Backup de internet (para online exams)

#### Recursos de Última Hora

**Quick Reference Guides:**
- Azure services cheat sheets
- PowerShell cmdlets reference
- Networking ports e protocols
- SKU comparison charts

**Mobile Apps para Revisão:**
- Microsoft Learn app
- Azure mobile app (para familiarização)
- Flashcard apps personalizados

### Estratégias Específicas por Domínio

#### Para Networking (25-30%):
- Foco em scenarios complexos
- Memorizar port numbers importantes
- Praticar subnet calculations
- Compreender routing scenarios

#### Para Computação (20-25%):
- Hands-on com diferentes deployment methods
- ARM templates practice
- Scaling scenarios
- Container orchestration

#### Para Identidade (15-20%):
- RBAC scenarios complexos
- Azure AD Connect troubleshooting
- B2B collaboration setup
- Conditional access policies

#### Para Storage (15-20%):
- Replication scenarios
- Performance optimization
- Backup strategies
- Data movement tools

#### Para Monitoring (10-15%):
- KQL query practice
- Alert configuration
- Dashboard creation
- Log analysis scenarios

---

## Conclusão

Este plano de estudos foi estruturado para fornecer uma preparação abrangente e prática para a certificação AZ-104. O sucesso depende da consistência nos estudos, prática hands-on regular e aplicação dos conceitos em cenários reais.

**Pontos-Chave para o Sucesso:**

1. **Prática Hands-On:** 60% do tempo em laboratórios práticos
2. **Consistency:** Estudo regular é melhor que sessões intensas esporádicas
3. **Community:** Participação ativa em fóruns e grupos de estudo
4. **Real-World Application:** Aplicar conceitos em projetos pessoais ou profissionais
5. **Feedback Loop:** Regular assessment através de practice exams

**Recursos de Suporte Contínuo:**
- Microsoft Documentation (sempre atualizada)
- Community forums para dúvidas específicas
- Hands-on labs para prática contínua
- Practice exams para assessment regular

Lembre-se: a certificação AZ-104 não é apenas sobre passar no exame, mas sobre desenvolver habilidades práticas que serão valiosas na carreira em cloud computing. Invista tempo na compreensão profunda dos conceitos e na aplicação prática dos conhecimentos.

**Boa sorte em sua jornada de certificação Azure!** 🚀

---

*Última atualização: Janeiro 2024*
*Versão do documento: 1.0*