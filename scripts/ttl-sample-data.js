// TTL Sample Data Script for MongoDB Kafka Connector Example
// This script inserts sample data that will expire using TTL indexes

print("Inserting TTL sample data...");

// Connect to the example database
db = db.getSiblingDB('exemplo');

try {
    // Sample sessions data with TTL expiration
    print("Inserting session data with TTL expiration...");
    
    const currentTime = new Date();
    
    // Create sessions that expire at different times
    const sessions = [
        {
            _id: ObjectId(),
            sessionId: "sess_demo_001",
            userId: "user_123",
            userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            ipAddress: "192.168.1.100",
            loginAt: currentTime,
            expiresAt: new Date(currentTime.getTime() + 30 * 1000), // Expires in 30 seconds
            isActive: true,
            metadata: {
                source: "web",
                features: ["dashboard", "reports"],
                lastActivity: currentTime
            }
        },
        {
            _id: ObjectId(),
            sessionId: "sess_demo_002", 
            userId: "user_456",
            userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            ipAddress: "192.168.1.101",
            loginAt: currentTime,
            expiresAt: new Date(currentTime.getTime() + 45 * 1000), // Expires in 45 seconds
            isActive: true,
            metadata: {
                source: "mobile",
                features: ["profile", "settings"],
                lastActivity: currentTime
            }
        },
        {
            _id: ObjectId(),
            sessionId: "sess_demo_003",
            userId: "user_789",
            userAgent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
            ipAddress: "192.168.1.102", 
            loginAt: currentTime,
            expiresAt: new Date(currentTime.getTime() + 60 * 1000), // Expires in 60 seconds
            isActive: true,
            metadata: {
                source: "desktop",
                features: ["admin", "analytics"],
                lastActivity: currentTime
            }
        }
    ];
    
    const sessionResult = db.sessions.insertMany(sessions);
    print(`✅ Inserted ${sessionResult.insertedIds.length} session documents with TTL expiration`);
    
    // Sample user tokens data with TTL expiration
    print("Inserting user token data with TTL expiration...");
    
    const tokens = [
        {
            _id: ObjectId(),
            tokenId: "token_api_001",
            userId: "user_123",
            tokenType: "api_key",
            scopes: ["read", "write"],
            createdAt: currentTime, // Will expire 60 seconds after this time
            isRevoked: false,
            metadata: {
                clientApp: "mobile_app",
                permissions: ["user.profile", "user.orders"]
            }
        },
        {
            _id: ObjectId(),
            tokenId: "token_refresh_002",
            userId: "user_456", 
            tokenType: "refresh_token",
            scopes: ["refresh"],
            createdAt: new Date(currentTime.getTime() + 10 * 1000), // Created 10 seconds later
            isRevoked: false,
            metadata: {
                clientApp: "web_app",
                permissions: ["user.profile"]
            }
        },
        {
            _id: ObjectId(),
            tokenId: "token_temp_003",
            userId: "user_789",
            tokenType: "temporary",
            scopes: ["admin"],
            createdAt: new Date(currentTime.getTime() + 20 * 1000), // Created 20 seconds later
            isRevoked: false,
            metadata: {
                clientApp: "admin_panel", 
                permissions: ["admin.users", "admin.system"]
            }
        }
    ];
    
    const tokenResult = db.user_tokens.insertMany(tokens);
    print(`✅ Inserted ${tokenResult.insertedIds.length} user token documents with TTL expiration`);
    
    // Insert some additional sessions for continuous demo
    print("Inserting additional sessions for continuous expiration demo...");
    
    // Create sessions that expire every 30 seconds for the next few minutes
    const additionalSessions = [];
    for (let i = 1; i <= 5; i++) {
        additionalSessions.push({
            _id: ObjectId(),
            sessionId: `sess_continuous_${String(i).padStart(3, '0')}`,
            userId: `demo_user_${i}`,
            userAgent: "TTL Demo Client",
            ipAddress: `192.168.1.${200 + i}`,
            loginAt: currentTime,
            expiresAt: new Date(currentTime.getTime() + (30 * i * 1000)), // Expires every 30 seconds
            isActive: true,
            metadata: {
                source: "ttl_demo",
                batchNumber: i,
                demoType: "continuous_expiration"
            }
        });
    }
    
    const additionalResult = db.sessions.insertMany(additionalSessions);
    print(`✅ Inserted ${additionalResult.insertedIds.length} additional sessions for continuous demo`);
    
    // Show expiration timeline
    print("\n📅 TTL Expiration Timeline:");
    print("Now:", currentTime.toISOString());
    
    // Query and show when each document will expire
    const allSessions = db.sessions.find().sort({ expiresAt: 1 });
    allSessions.forEach(session => {
        const expiresIn = Math.round((session.expiresAt.getTime() - currentTime.getTime()) / 1000);
        print(`Session ${session.sessionId}: expires in ${expiresIn} seconds (${session.expiresAt.toISOString()})`);
    });
    
    print("\nUser tokens expire 60 seconds after their createdAt time:");
    const allTokens = db.user_tokens.find().sort({ createdAt: 1 });
    allTokens.forEach(token => {
        const expiresAt = new Date(token.createdAt.getTime() + 60 * 1000);
        const expiresIn = Math.round((expiresAt.getTime() - currentTime.getTime()) / 1000);
        print(`Token ${token.tokenId}: expires in ${expiresIn} seconds (${expiresAt.toISOString()})`);
    });
    
    print("\n🔍 To monitor TTL expiration events:");
    print("1. Run: make ttl-monitor");
    print("2. Wait and watch for delete operations in Change Streams");
    print("3. MongoDB TTL background task runs every 60 seconds");
    
    // Show collection counts
    print("\n📊 Collection statistics:");
    print(`Sessions: ${db.sessions.countDocuments()}`);
    print(`User tokens: ${db.user_tokens.countDocuments()}`);
    
    print("\n✅ TTL sample data insertion completed successfully!");
    
} catch (error) {
    print("❌ Error inserting TTL sample data: " + error);
    throw error;
}