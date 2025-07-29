// TTL (Time To Live) Index Setup Script for MongoDB Kafka Connector Example
// This script demonstrates how to create TTL indexes for automatic document expiration

print("Setting up TTL (Time To Live) index example...");

// Connect to the example database
db = db.getSiblingDB('exemplo');

// Create the sessions collection if it doesn't exist
print("Creating sessions collection...");

try {
    // Create TTL index on expiresAt field
    // Documents will be automatically deleted when expiresAt time is reached
    print("Creating TTL index on sessions.expiresAt field...");
    
    const indexResult = db.sessions.createIndex(
        { "expiresAt": 1 }, 
        { 
            expireAfterSeconds: 0,  // Expire immediately when expiresAt time is reached
            name: "ttl_expiresAt_index"
        }
    );
    
    print(`TTL index created: ${indexResult}`);
    
    // Create additional TTL index example for user tokens with different expiration
    print("Creating TTL index on user_tokens.createdAt field (60 seconds expiration)...");
    
    const tokenIndexResult = db.user_tokens.createIndex(
        { "createdAt": 1 }, 
        { 
            expireAfterSeconds: 60,  // Expire 60 seconds after createdAt time
            name: "ttl_user_tokens_index"
        }
    );
    
    print(`User tokens TTL index created: ${tokenIndexResult}`);
    
    // Show created indexes
    print("\nTTL indexes created:");
    print("Sessions collection indexes:");
    db.sessions.getIndexes().forEach(index => {
        if (index.expireAfterSeconds !== undefined) {
            print(`  - ${index.name}: expires after ${index.expireAfterSeconds} seconds`);
            print(`    Key: ${JSON.stringify(index.key)}`);
        }
    });
    
    print("\nUser tokens collection indexes:");
    db.user_tokens.getIndexes().forEach(index => {
        if (index.expireAfterSeconds !== undefined) {
            print(`  - ${index.name}: expires after ${index.expireAfterSeconds} seconds`);
            print(`    Key: ${JSON.stringify(index.key)}`);
        }
    });
    
    print("\n✅ TTL indexes setup completed successfully!");
    print("\nHow TTL works:");
    print("1. Sessions: Documents expire when 'expiresAt' time is reached");
    print("2. User tokens: Documents expire 60 seconds after 'createdAt' time");
    print("3. MongoDB runs a background task every 60 seconds to remove expired documents");
    print("4. Change Streams will capture these deletions as 'delete' operations");
    
} catch (error) {
    print("❌ Error setting up TTL indexes: " + error);
    throw error;
}