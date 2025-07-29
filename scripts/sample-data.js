// Script para inserção de dados de exemplo no MongoDB
// Autor: MongoDB Kafka Connector Example
// Data: 2024

// Função para log com timestamp
function log(message) {
    print(`[${new Date().toISOString()}] ${message}`);
}

// Função para gerar dados aleatórios
function generateRandomData() {
    const categories = ['Electronics', 'Books', 'Clothing', 'Home', 'Sports', 'Toys', 'Beauty', 'Automotive'];
    const adjectives = ['Amazing', 'Fantastic', 'Premium', 'Professional', 'Elegant', 'Modern', 'Classic', 'Innovative'];
    const nouns = ['Product', 'Item', 'Device', 'Tool', 'Accessory', 'Kit', 'Set', 'Solution'];
    
    const randomCategory = categories[Math.floor(Math.random() * categories.length)];
    const randomAdjective = adjectives[Math.floor(Math.random() * adjectives.length)];
    const randomNoun = nouns[Math.floor(Math.random() * nouns.length)];
    
    return {
        name: `${randomAdjective} ${randomNoun}`,
        description: `Este é um ${randomNoun.toLowerCase()} ${randomAdjective.toLowerCase()} da categoria ${randomCategory}`,
        price: Math.round((Math.random() * 1000 + 10) * 100) / 100,
        category: randomCategory,
        created_at: new Date(),
        updated_at: new Date(),
        in_stock: Math.random() > 0.2, // 80% chance de estar em estoque
        stock_quantity: Math.floor(Math.random() * 100),
        sku: `SKU-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
        weight: Math.round((Math.random() * 10 + 0.1) * 100) / 100,
        dimensions: {
            length: Math.round((Math.random() * 50 + 1) * 100) / 100,
            width: Math.round((Math.random() * 50 + 1) * 100) / 100,
            height: Math.round((Math.random() * 50 + 1) * 100) / 100
        },
        tags: [
            randomCategory.toLowerCase(),
            randomAdjective.toLowerCase(),
            Math.random() > 0.5 ? 'popular' : 'new',
            Math.random() > 0.7 ? 'featured' : 'standard'
        ],
        supplier: {
            name: `Supplier ${Math.floor(Math.random() * 100) + 1}`,
            contact: `supplier${Math.floor(Math.random() * 100) + 1}@example.com`,
            rating: Math.round((Math.random() * 5 + 1) * 10) / 10
        }
    };
}

// Função para gerar dados de usuários
function generateUserData() {
    const firstNames = ['João', 'Maria', 'Pedro', 'Ana', 'Carlos', 'Lucia', 'Fernando', 'Beatriz', 'Ricardo', 'Carla'];
    const lastNames = ['Silva', 'Santos', 'Oliveira', 'Souza', 'Lima', 'Pereira', 'Costa', 'Rodrigues', 'Almeida', 'Nascimento'];
    
    const firstName = firstNames[Math.floor(Math.random() * firstNames.length)];
    const lastName = lastNames[Math.floor(Math.random() * lastNames.length)];
    
    return {
        name: `${firstName} ${lastName}`,
        email: `${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com`,
        age: Math.floor(Math.random() * 50) + 18,
        created_at: new Date(),
        updated_at: new Date(),
        active: Math.random() > 0.1, // 90% chance de estar ativo
        profile: {
            phone: `+55 11 9${Math.floor(Math.random() * 100000000).toString().padStart(8, '0')}`,
            address: {
                street: `Rua ${Math.floor(Math.random() * 1000) + 1}`,
                number: Math.floor(Math.random() * 9999) + 1,
                city: 'São Paulo',
                state: 'SP',
                zipcode: `${Math.floor(Math.random() * 100000).toString().padStart(5, '0')}-${Math.floor(Math.random() * 1000).toString().padStart(3, '0')}`
            },
            preferences: {
                newsletter: Math.random() > 0.3,
                notifications: Math.random() > 0.2
            }
        }
    };
}

// Função para gerar dados de pedidos
function generateOrderData(users, products) {
    if (users.length === 0 || products.length === 0) {
        return null;
    }
    
    const user = users[Math.floor(Math.random() * users.length)];
    const orderProducts = [];
    const numProducts = Math.floor(Math.random() * 3) + 1; // 1-3 produtos por pedido
    
    for (let i = 0; i < numProducts; i++) {
        const product = products[Math.floor(Math.random() * products.length)];
        const quantity = Math.floor(Math.random() * 3) + 1;
        
        orderProducts.push({
            product_id: product._id,
            name: product.name,
            price: product.price,
            quantity: quantity,
            total: product.price * quantity
        });
    }
    
    const totalAmount = orderProducts.reduce((sum, item) => sum + item.total, 0);
    
    return {
        user_id: user._id,
        user_email: user.email,
        products: orderProducts,
        total_amount: Math.round(totalAmount * 100) / 100,
        status: ['pending', 'processing', 'shipped', 'delivered'][Math.floor(Math.random() * 4)],
        created_at: new Date(),
        updated_at: new Date(),
        shipping_address: user.profile.address,
        payment_method: ['credit_card', 'debit_card', 'pix', 'boleto'][Math.floor(Math.random() * 4)]
    };
}

// Função principal
function main() {
    try {
        log('=== Iniciando inserção de dados de exemplo ===');
        
        // Conectar ao banco de dados
        const db = connect('mongodb://admin:password123@localhost:27017/inventory?authSource=admin');
        
        log('Conectado ao MongoDB com sucesso!');
        
        // Limpar dados existentes (opcional)
        const clearExisting = false; // Mude para true se quiser limpar dados existentes
        
        if (clearExisting) {
            log('Limpando dados existentes...');
            db.products.deleteMany({});
            db.users.deleteMany({});
            db.orders.deleteMany({});
            log('Dados existentes removidos.');
        }
        
        // Inserir produtos
        log('Inserindo dados de produtos...');
        const products = [];
        for (let i = 0; i < 50; i++) {
            products.push(generateRandomData());
        }
        
        const productResult = db.products.insertMany(products);
        log(`${productResult.insertedIds.length} produtos inseridos com sucesso!`);
        
        // Buscar produtos inseridos para usar nos pedidos
        const insertedProducts = db.products.find({}).toArray();
        
        // Inserir usuários
        log('Inserindo dados de usuários...');
        const users = [];
        for (let i = 0; i < 20; i++) {
            users.push(generateUserData());
        }
        
        const userResult = db.users.insertMany(users);
        log(`${userResult.insertedIds.length} usuários inseridos com sucesso!`);
        
        // Buscar usuários inseridos para usar nos pedidos
        const insertedUsers = db.users.find({}).toArray();
        
        // Inserir pedidos
        log('Inserindo dados de pedidos...');
        const orders = [];
        for (let i = 0; i < 30; i++) {
            const order = generateOrderData(insertedUsers, insertedProducts);
            if (order) {
                orders.push(order);
            }
        }
        
        if (orders.length > 0) {
            const orderResult = db.orders.insertMany(orders);
            log(`${orderResult.insertedIds.length} pedidos inseridos com sucesso!`);
        }
        
        // Inserir alguns dados adicionais de exemplo
        log('Inserindo dados adicionais...');
        
        // Categoria especial de produtos
        const featuredProducts = [
            {
                name: "Laptop Gaming Pro",
                description: "Laptop de alta performance para jogos e trabalho profissional",
                price: 2999.99,
                category: "Electronics",
                created_at: new Date(),
                updated_at: new Date(),
                in_stock: true,
                stock_quantity: 15,
                sku: "LAPTOP-GAMING-001",
                featured: true,
                specifications: {
                    processor: "Intel Core i7",
                    memory: "16GB RAM",
                    storage: "512GB SSD",
                    graphics: "NVIDIA RTX 3060"
                }
            },
            {
                name: "Smartphone Premium",
                description: "Smartphone top de linha com câmera profissional",
                price: 1499.99,
                category: "Electronics", 
                created_at: new Date(),
                updated_at: new Date(),
                in_stock: true,
                stock_quantity: 25,
                sku: "PHONE-PREMIUM-001",
                featured: true,
                specifications: {
                    screen: "6.7 inch OLED",
                    camera: "108MP Triple Camera",
                    battery: "5000mAh",
                    storage: "256GB"
                }
            }
        ];
        
        db.products.insertMany(featuredProducts);
        log('Produtos especiais inseridos!');
        
        // Estatísticas finais
        log('=== Estatísticas dos dados inseridos ===');
        log(`Total de produtos: ${db.products.countDocuments()}`);
        log(`Total de usuários: ${db.users.countDocuments()}`);
        log(`Total de pedidos: ${db.orders.countDocuments()}`);
        
        // Criar alguns índices para melhor performance
        log('Criando índices...');
        db.products.createIndex({ "category": 1 });
        db.products.createIndex({ "created_at": -1 });
        db.products.createIndex({ "price": 1 });
        db.users.createIndex({ "email": 1 }, { unique: true });
        db.orders.createIndex({ "user_id": 1 });
        db.orders.createIndex({ "created_at": -1 });
        log('Índices criados com sucesso!');
        
        log('=== Inserção de dados concluída com sucesso! ===');
        log('');
        log('Para verificar os dados inseridos:');
        log('  db.products.find().limit(5)');
        log('  db.users.find().limit(5)');
        log('  db.orders.find().limit(5)');
        log('');
        log('Para monitorar as mudanças no Kafka:');
        log('  docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic mongodb.inventory.products --from-beginning');
        
    } catch (error) {
        log('Erro durante a inserção de dados: ' + error.message);
        throw error;
    }
}

// Executar função principal
main();