// Sample Data Script for MongoDB Kafka Connector Example

print("Starting sample data insertion...");

// Connect to the example database
db = db.getSiblingDB('exemplo');

// Sample Users Data
const users = [
    {
        _id: ObjectId(),
        name: "João Silva",
        email: "joao.silva@example.com",
        age: 30,
        department: "Engineering",
        salary: 75000,
        createdAt: new Date(),
        address: {
            street: "Rua das Flores, 123",
            city: "São Paulo",
            state: "SP",
            zipCode: "01234-567"
        },
        skills: ["JavaScript", "Python", "MongoDB"]
    },
    {
        _id: ObjectId(),
        name: "Maria Santos",
        email: "maria.santos@example.com",
        age: 28,
        department: "Marketing",
        salary: 65000,
        createdAt: new Date(),
        address: {
            street: "Av. Paulista, 456",
            city: "São Paulo",
            state: "SP",
            zipCode: "01311-100"
        },
        skills: ["Digital Marketing", "Analytics", "SEO"]
    },
    {
        _id: ObjectId(),
        name: "Carlos Oliveira",
        email: "carlos.oliveira@example.com",
        age: 35,
        department: "Sales",
        salary: 80000,
        createdAt: new Date(),
        address: {
            street: "Rua Augusta, 789",
            city: "São Paulo",
            state: "SP",
            zipCode: "01305-100"
        },
        skills: ["Sales", "CRM", "Negotiation"]
    }
];

// Sample Products Data
const products = [
    {
        _id: ObjectId(),
        name: "Laptop Dell Inspiron",
        sku: "LAPTOP-DELL-001",
        price: 2500.00,
        category: "Electronics",
        description: "High-performance laptop for professionals",
        inStock: true,
        quantity: 50,
        createdAt: new Date(),
        specifications: {
            processor: "Intel i7",
            memory: "16GB RAM",
            storage: "512GB SSD",
            screen: "15.6 inch"
        },
        tags: ["laptop", "dell", "professional"]
    },
    {
        _id: ObjectId(),
        name: "Mouse Logitech MX Master",
        sku: "MOUSE-LOG-001",
        price: 299.99,
        category: "Accessories",
        description: "Ergonomic wireless mouse",
        inStock: true,
        quantity: 100,
        createdAt: new Date(),
        specifications: {
            type: "Wireless",
            battery: "Rechargeable",
            compatibility: "Multi-device"
        },
        tags: ["mouse", "logitech", "wireless"]
    },
    {
        _id: ObjectId(),
        name: "Monitor Samsung 24\"",
        sku: "MONITOR-SAM-001",
        price: 899.00,
        category: "Electronics",
        description: "Full HD monitor with excellent color accuracy",
        inStock: false,
        quantity: 0,
        createdAt: new Date(),
        specifications: {
            size: "24 inch",
            resolution: "1920x1080",
            panel: "IPS",
            refreshRate: "60Hz"
        },
        tags: ["monitor", "samsung", "full-hd"]
    }
];

// Sample Orders Data
const orders = [
    {
        _id: ObjectId(),
        userId: users[0]._id,
        orderNumber: "ORD-2024-001",
        status: "completed",
        totalAmount: 3199.99,
        createdAt: new Date(Date.now() - 86400000), // 1 day ago
        updatedAt: new Date(),
        items: [
            {
                productId: products[0]._id,
                productName: "Laptop Dell Inspiron",
                quantity: 1,
                price: 2500.00
            },
            {
                productId: products[1]._id,
                productName: "Mouse Logitech MX Master",
                quantity: 1,
                price: 299.99
            }
        ],
        shipping: {
            address: users[0].address,
            method: "Standard",
            cost: 29.99
        },
        payment: {
            method: "Credit Card",
            status: "paid",
            transactionId: "TXN-12345"
        }
    },
    {
        _id: ObjectId(),
        userId: users[1]._id,
        orderNumber: "ORD-2024-002",
        status: "processing",
        totalAmount: 929.98,
        createdAt: new Date(Date.now() - 43200000), // 12 hours ago
        updatedAt: new Date(),
        items: [
            {
                productId: products[2]._id,
                productName: "Monitor Samsung 24\"",
                quantity: 1,
                price: 899.00
            }
        ],
        shipping: {
            address: users[1].address,
            method: "Express",
            cost: 49.99
        },
        payment: {
            method: "PIX",
            status: "paid",
            transactionId: "PIX-67890"
        }
    }
];

try {
    // Insert sample data
    print("Inserting users...");
    const userResult = db.users.insertMany(users);
    print(`Inserted ${userResult.insertedIds.length} users`);

    print("Inserting products...");
    const productResult = db.products.insertMany(products);
    print(`Inserted ${productResult.insertedIds.length} products`);

    print("Inserting orders...");
    const orderResult = db.orders.insertMany(orders);
    print(`Inserted ${orderResult.insertedIds.length} orders`);

    // Perform some updates to generate change stream events
    print("Performing sample updates...");
    
    // Update user information
    db.users.updateOne(
        { email: "joao.silva@example.com" },
        { 
            $set: { 
                salary: 78000,
                lastUpdated: new Date()
            }
        }
    );
    
    // Update product stock
    db.products.updateOne(
        { sku: "LAPTOP-DELL-001" },
        { 
            $inc: { quantity: -1 },
            $set: { lastUpdated: new Date() }
        }
    );
    
    // Update order status
    db.orders.updateOne(
        { orderNumber: "ORD-2024-002" },
        { 
            $set: { 
                status: "shipped",
                shippedAt: new Date(),
                updatedAt: new Date()
            }
        }
    );

    // Insert additional real-time data
    print("Inserting real-time events...");
    
    // New user registration
    db.users.insertOne({
        _id: ObjectId(),
        name: "Ana Costa",
        email: "ana.costa@example.com",
        age: 26,
        department: "Design",
        salary: 55000,
        createdAt: new Date(),
        address: {
            street: "Rua Oscar Freire, 321",
            city: "São Paulo",
            state: "SP",
            zipCode: "01426-001"
        },
        skills: ["UI/UX", "Figma", "Adobe Creative Suite"]
    });

    // New product launch
    db.products.insertOne({
        _id: ObjectId(),
        name: "Teclado Mecânico RGB",
        sku: "KEYBOARD-RGB-001",
        price: 450.00,
        category: "Accessories",
        description: "Mechanical keyboard with RGB lighting",
        inStock: true,
        quantity: 75,
        createdAt: new Date(),
        specifications: {
            switchType: "Cherry MX Blue",
            lighting: "RGB",
            connectivity: "USB-C"
        },
        tags: ["keyboard", "mechanical", "rgb", "gaming"]
    });

    print("Sample data insertion completed successfully!");
    
    // Show collection counts
    print("\nCollection statistics:");
    print(`Users: ${db.users.countDocuments()}`);
    print(`Products: ${db.products.countDocuments()}`);
    print(`Orders: ${db.orders.countDocuments()}`);
    
} catch (error) {
    print("Error inserting sample data: " + error);
}