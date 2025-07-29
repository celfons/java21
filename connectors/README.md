# MongoDB Kafka Connectors - Operation Filters

This directory contains the configurations for MongoDB Kafka Connect connectors with filters by operation type.

## 📁 File Structure

- `mongo-insert-connector.json` - Connector to capture only INSERT operations
- `mongo-update-connector.json` - Connector to capture only UPDATE operations  
- `mongo-delete-connector.json` - Connector to capture only DELETE operations

## 🔧 How Filters Work

Each connector uses the MongoDB Change Stream aggregation pipeline to filter events:

```json
"pipeline": "[{\"$match\": {\"operationType\": \"insert\"}}]"
```

### Available Operation Types

- `insert` - Insertion of new documents
- `update` - Update of existing documents
- `delete` - Deletion of documents
- `replace` - Complete replacement of documents
- `drop` - Collection deletion
- `rename` - Collection renaming
- `dropDatabase` - Database deletion
- `invalidate` - Change stream invalidation

## 📊 Topic Configuration

Each connector sends to topics with different prefixes:

| Connector | Prefix | Example Topic |
|----------|---------|---------------|
| INSERT | `mongo-insert` | `mongo-insert.exemplo.users` |
| UPDATE | `mongo-update` | `mongo-update.exemplo.users` |
| DELETE | `mongo-delete` | `mongo-delete.exemplo.users` |

## 🚀 Usage

To apply these configurations, run:

```bash
# Via Makefile
make setup-multi-connectors

# Or directly
./scripts/setup-multi-connectors.sh
```

## ⚙️ Customization

### Modify Database/Collection

To change the database or filter specific collections:

```json
{
  "database": "my_database",
  "collection": "my_collection"
}
```

### More Complex Filters

Example of advanced pipeline:

```json
"pipeline": "[
  {\"$match\": {
    \"operationType\": \"insert\",
    \"ns.coll\": {\"$in\": [\"users\", \"products\"]}
  }}
]"
```

### Performance Settings

```json
{
  "poll.max.batch.size": "1000",
  "poll.await.time.ms": "5000",
  "tasks.max": "2"
}
```

## 🔍 Monitoring

Each connector has its own Dead Letter Queue (DLQ):

- `mongo-insert-dlq` - For INSERT connector errors
- `mongo-update-dlq` - For UPDATE connector errors
- `mongo-delete-dlq` - For DELETE connector errors

## 📚 References

- [MongoDB Kafka Connector Documentation](https://docs.mongodb.com/kafka-connector/)
- [MongoDB Change Streams](https://docs.mongodb.com/manual/changeStreams/)
- [Kafka Connect Documentation](https://docs.confluent.io/platform/current/connect/index.html)