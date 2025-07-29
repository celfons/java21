// MongoDB Replica Set Initialization Script
print("Starting replica set initialization...");

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

// Initialize replica set
try {
    rs.initiate(config);
    print("Replica set initiated successfully");
} catch (error) {
    print("Error initiating replica set: " + error);
}

// Wait for replica set to be ready
var attempts = 0;
var maxAttempts = 30;

while (attempts < maxAttempts) {
    try {
        var status = rs.status();
        if (status.ok === 1) {
            print("Replica set is ready");
            break;
        }
    } catch (error) {
        print("Waiting for replica set... Attempt " + (attempts + 1));
        sleep(2000);
        attempts++;
    }
}

if (attempts >= maxAttempts) {
    print("ERROR: Replica set failed to initialize within expected time");
} else {
    print("Replica set initialization completed successfully");
    
    // Create application database and user
    db = db.getSiblingDB('exemplo');
    
    // Create a sample collection with some initial data
    db.createCollection("users");
    db.createCollection("products");
    db.createCollection("orders");
    
    print("Created sample collections in 'exemplo' database");
    
    // Create indexes for better performance
    db.users.createIndex({ "email": 1 }, { unique: true });
    db.products.createIndex({ "sku": 1 }, { unique: true });
    db.orders.createIndex({ "userId": 1 });
    db.orders.createIndex({ "createdAt": 1 });
    
    print("Created indexes for sample collections");
}