# MongoDB Kafka Connectors - Filtros por Operação

Este diretório contém as configurações dos conectores MongoDB Kafka Connect com filtros por tipo de operação.

## 📁 Estrutura dos Arquivos

- `mongo-insert-connector.json` - Conector para capturar apenas operações INSERT
- `mongo-update-connector.json` - Conector para capturar apenas operações UPDATE  
- `mongo-delete-connector.json` - Conector para capturar apenas operações DELETE

## 🔧 Como Funcionam os Filtros

Cada conector utiliza o pipeline de agregação do MongoDB Change Stream para filtrar eventos:

```json
"pipeline": "[{\"$match\": {\"operationType\": \"insert\"}}]"
```

### Tipos de Operação Disponíveis

- `insert` - Inserção de novos documentos
- `update` - Atualização de documentos existentes
- `delete` - Exclusão de documentos
- `replace` - Substituição completa de documentos
- `drop` - Exclusão de coleção
- `rename` - Renomeação de coleção
- `dropDatabase` - Exclusão de database
- `invalidate` - Invalidação do change stream

## 📊 Configurações dos Tópicos

Cada conector envia para tópicos com prefixos diferentes:

| Conector | Prefixo | Exemplo de Tópico |
|----------|---------|-------------------|
| INSERT | `mongo-insert` | `mongo-insert.exemplo.users` |
| UPDATE | `mongo-update` | `mongo-update.exemplo.users` |
| DELETE | `mongo-delete` | `mongo-delete.exemplo.users` |

## 🚀 Uso

Para aplicar essas configurações, execute:

```bash
# Via Makefile
make setup-multi-connectors

# Ou diretamente
./scripts/setup-multi-connectors.sh
```

## ⚙️ Personalização

### Modificar Database/Collection

Para alterar o database ou filtrar collections específicas:

```json
{
  "database": "meu_banco",
  "collection": "minha_collection"
}
```

### Filtros Mais Complexos

Exemplo de pipeline mais avançado:

```json
"pipeline": "[
  {\"$match\": {
    \"operationType\": \"insert\",
    \"ns.coll\": {\"$in\": [\"users\", \"products\"]}
  }}
]"
```

### Configurações de Performance

```json
{
  "poll.max.batch.size": "1000",
  "poll.await.time.ms": "5000",
  "tasks.max": "2"
}
```

## 🔍 Monitoramento

Cada conector possui sua própria Dead Letter Queue (DLQ):

- `mongo-insert-dlq` - Para erros do conector INSERT
- `mongo-update-dlq` - Para erros do conector UPDATE
- `mongo-delete-dlq` - Para erros do conector DELETE

## 📚 Referências

- [MongoDB Kafka Connector Documentation](https://docs.mongodb.com/kafka-connector/)
- [MongoDB Change Streams](https://docs.mongodb.com/manual/changeStreams/)
- [Kafka Connect Documentation](https://docs.confluent.io/platform/current/connect/index.html)