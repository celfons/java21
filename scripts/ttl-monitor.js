// TTL Change Stream Monitor for MongoDB Kafka Connector Example
// This script monitors Change Streams to capture TTL expiration events

print("🔍 Starting TTL Change Stream Monitor...");
print("This will monitor for document deletions caused by TTL expiration");
print("Press Ctrl+C to stop monitoring");
print("=" * 70);

// Connect to the example database
db = db.getSiblingDB('exemplo');

try {
    // Create change stream to monitor all delete operations
    // TTL deletions appear as 'delete' operations in Change Streams
    const changeStream = db.watch([
        {
            // Filter for delete operations only
            $match: {
                "operationType": "delete"
            }
        }
    ], {
        fullDocument: "whenAvailable"
    });
    
    print(`🚀 Change Stream started at: ${new Date().toISOString()}`);
    print("📋 Monitoring for TTL expiration events (delete operations)...");
    print("📝 TTL expiration events will show as 'delete' operations");
    print("");
    
    let eventCount = 0;
    
    // Monitor the change stream
    while (changeStream.hasNext()) {
        const event = changeStream.next();
        eventCount++;
        
        const timestamp = new Date(event.clusterTime.getTime() * 1000).toISOString();
        const collection = event.ns.coll;
        const database = event.ns.db;
        
        print(`🗑️  TTL EXPIRATION EVENT #${eventCount}`);
        print(`   Time: ${timestamp}`);
        print(`   Database: ${database}`);
        print(`   Collection: ${collection}`);
        print(`   Operation: ${event.operationType}`);
        print(`   Document ID: ${JSON.stringify(event.documentKey)}`);
        
        // Try to identify if this is a TTL deletion
        if (collection === 'sessions') {
            print(`   🕒 TTL Type: Session expiration (expiresAt field)`);
            print(`   📋 Session ID: ${event.documentKey._id ? event.documentKey._id.$oid : 'Unknown'}`);
        } else if (collection === 'user_tokens') {
            print(`   🕒 TTL Type: User token expiration (createdAt + 60 seconds)`);
            print(`   📋 Token ID: ${event.documentKey._id ? event.documentKey._id.$oid : 'Unknown'}`);
        } else {
            print(`   🕒 TTL Type: General TTL expiration or manual deletion`);
        }
        
        print(`   📦 Full Event Data:`);
        print(`   ${JSON.stringify(event, null, 4)}`);
        print("=" * 70);
        
        // Show current collection counts
        const sessionsCount = db.sessions.countDocuments();
        const tokensCount = db.user_tokens.countDocuments();
        print(`📊 Current counts - Sessions: ${sessionsCount}, Tokens: ${tokensCount}`);
        print("");
    }
    
} catch (error) {
    if (error.message.includes("interrupted")) {
        print("\n🛑 Change Stream monitoring stopped by user");
    } else {
        print(`❌ Error monitoring Change Stream: ${error.message}`);
        
        // Provide troubleshooting help
        print("\n🔧 Troubleshooting:");
        print("1. Ensure MongoDB is running as a replica set");
        print("2. Check if TTL indexes are properly created: db.sessions.getIndexes()");
        print("3. Verify TTL sample data exists: db.sessions.find()");
        print("4. TTL background task runs every 60 seconds in MongoDB");
    }
}

print("\n📚 About TTL and Change Streams:");
print("- TTL (Time To Live) indexes automatically delete expired documents");
print("- These deletions appear as 'delete' operations in Change Streams"); 
print("- MongoDB Kafka Connector will capture these as delete events");
print("- TTL background task runs every 60 seconds");
print("- Documents may not be deleted exactly at expiration time");
print("- Change Streams provide real-time notification of TTL deletions");