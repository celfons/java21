// MongoDB Replica Set Initialization Script
print("Starting replica set initialization...");

// Wait a bit more to ensure all instances are ready
sleep(5000);

var config = {
    "_id": "rs0",
    "version": 1,
    "members": [
        {
            "_id": 0,
            "host": "mongo1:27017",
            "priority": 2
        },
        {
            "_id": 1,
            "host": "mongo2:27017",
            "priority": 1
        },
        {
            "_id": 2,
            "host": "mongo3:27017",
            "priority": 1
        }
    ]
};

// Check if replica set is already initialized
try {
    var status = rs.status();
    if (status.ok === 1) {
        print("Replica set is already initialized and healthy");
        print("Current members:");
        status.members.forEach(function(member) {
            print("  - " + member.name + " (" + member.stateStr + ")");
        });
        
        // Verify all members are present
        var expectedMembers = ["mongo1:27017", "mongo2:27017", "mongo3:27017"];
        var actualMembers = status.members.map(function(m) { return m.name; });
        var allMembersPresent = expectedMembers.every(function(expected) {
            return actualMembers.includes(expected);
        });
        
        if (allMembersPresent && status.members.length === 3) {
            print("All three members are present. Replica set setup is complete.");
            quit(0);
        } else {
            print("Warning: Not all expected members are present. Continuing with reconfiguration...");
        }
    }
} catch (error) {
    print("Replica set not initialized yet, proceeding with initialization...");
    
    // Initialize replica set
    try {
        var result = rs.initiate(config);
        print("Replica set initiate result: " + JSON.stringify(result));
        
        if (result.ok === 1) {
            print("Replica set initiated successfully");
        } else {
            print("Warning: Replica set initiation returned: " + JSON.stringify(result));
        }
    } catch (error) {
        print("Error initiating replica set: " + error);
        print("This might be normal if the replica set is already being initialized");
    }
}

// Wait for replica set to be ready with more robust checking
var attempts = 0;
var maxAttempts = 60; // Increased from 30 to 60
var success = false;

print("Waiting for replica set to become ready...");

while (attempts < maxAttempts && !success) {
    try {
        var status = rs.status();
        if (status.ok === 1) {
            var primaryFound = false;
            var healthyMembers = 0;
            var expectedMembers = ["mongo1:27017", "mongo2:27017", "mongo3:27017"];
            var actualMembers = [];
            
            print("Replica set status check #" + (attempts + 1) + ":");
            status.members.forEach(function(member) {
                print("  - " + member.name + ": " + member.stateStr + " (health: " + member.health + ")");
                actualMembers.push(member.name);
                if (member.stateStr === "PRIMARY") {
                    primaryFound = true;
                    if (member.name === "mongo1:27017") {
                        print("  ✓ mongo1 is PRIMARY as expected");
                    } else {
                        print("  ! Primary is not mongo1, but " + member.name);
                    }
                }
                if (member.health === 1) {
                    healthyMembers++;
                }
            });
            
            // Check if all expected members are present
            var allMembersPresent = expectedMembers.every(function(expected) {
                return actualMembers.includes(expected);
            });
            
            if (primaryFound && healthyMembers >= 2 && allMembersPresent && status.members.length === 3) {
                print("Replica set is ready with primary and all healthy members");
                success = true;
                break;
            } else {
                print("Waiting for replica set readiness...");
                print("  - Primary found: " + primaryFound);
                print("  - Healthy members: " + healthyMembers + "/3");
                print("  - All members present: " + allMembersPresent + " (" + actualMembers.length + "/3)");
            }
        } else {
            print("Replica set status not OK: " + JSON.stringify(status));
        }
    } catch (error) {
        print("Waiting for replica set... Attempt " + (attempts + 1) + " - " + error);
    }
    
    sleep(3000); // Wait 3 seconds between attempts
    attempts++;
}

if (!success && attempts >= maxAttempts) {
    print("ERROR: Replica set failed to initialize within expected time");
    print("Final status attempt:");
    try {
        var finalStatus = rs.status();
        print("Final status: " + JSON.stringify(finalStatus));
    } catch (error) {
        print("Could not get final status: " + error);
    }
    quit(1);
} else {
    print("✓ Replica set initialization completed successfully");
    
    // Create application database and collections
    try {
        db = db.getSiblingDB('exemplo');
        
        // Create sample collections
        db.createCollection("users");
        db.createCollection("products");
        db.createCollection("orders");
        
        print("✓ Created sample collections in 'exemplo' database");
        
        // Create indexes for better performance
        db.users.createIndex({ "email": 1 }, { unique: true });
        db.products.createIndex({ "sku": 1 }, { unique: true });
        db.orders.createIndex({ "userId": 1 });
        db.orders.createIndex({ "createdAt": 1 });
        
        print("✓ Created indexes for sample collections");
        
        // Insert sample data
        db.users.insertOne({
            email: "admin@example.com",
            name: "Administrator",
            role: "admin",
            createdAt: new Date()
        });
        
        db.products.insertOne({
            sku: "SAMPLE001",
            name: "Sample Product",
            price: 99.99,
            category: "electronics",
            createdAt: new Date()
        });
        
        print("✓ Inserted sample data");
        
    } catch (error) {
        print("Warning: Could not create sample database/collections: " + error);
    }
    
    print("=== Replica Set Summary ===");
    print("Replica set 'rs0' is ready with members:");
    print("  - mongo1:27017 (PRIMARY, priority: 2)");
    print("  - mongo2:27017 (SECONDARY, priority: 1)");
    print("  - mongo3:27017 (SECONDARY, priority: 1)");
    print("Database 'exemplo' created with sample collections and indexes");
    print("Connection string: mongodb://mongo1:27017,mongo2:27017,mongo3:27017/?replicaSet=rs0");
}