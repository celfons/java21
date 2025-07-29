// Inicialização do Replica Set MongoDB
// Este script é executado automaticamente quando o container MongoDB inicia

print('Iniciando configuração do Replica Set...');

try {
    // Aguarda o MongoDB estar pronto
    while (true) {
        try {
            db.adminCommand({ ping: 1 });
            break;
        } catch (e) {
            print('Aguardando MongoDB estar pronto...');
            sleep(1000);
        }
    }

    // Configuração do Replica Set
    const config = {
        _id: "rs0",
        version: 1,
        members: [
            {
                _id: 0,
                host: "mongo-primary:27017",
                priority: 2
            },
            {
                _id: 1,
                host: "mongo-secondary-1:27017",
                priority: 1
            },
            {
                _id: 2,
                host: "mongo-secondary-2:27017",
                priority: 1
            }
        ]
    };

    // Verifica se o replica set já foi inicializado
    try {
        const status = rs.status();
        print('Replica Set já inicializado:');
        printjson(status);
    } catch (e) {
        // Se não foi inicializado, inicializa agora
        print('Inicializando Replica Set...');
        const result = rs.initiate(config);
        printjson(result);
        
        if (result.ok === 1) {
            print('Replica Set inicializado com sucesso!');
            
            // Aguarda a eleição do primary
            print('Aguardando eleição do primary...');
            while (true) {
                try {
                    const status = rs.status();
                    const primary = status.members.find(m => m.stateStr === 'PRIMARY');
                    if (primary) {
                        print('Primary eleito: ' + primary.name);
                        break;
                    }
                } catch (e) {
                    // Continua tentando
                }
                sleep(1000);
            }
            
            // Cria database e collection de exemplo
            try {
                db = db.getSiblingDB('inventory');
                db.products.insertOne({
                    name: "Produto Exemplo",
                    description: "Este é um produto de exemplo para testar o MongoDB Kafka Connector",
                    price: 29.99,
                    category: "Exemplo",
                    created_at: new Date(),
                    in_stock: true
                });
                print('Database e collection de exemplo criados!');
            } catch (e) {
                print('Erro ao criar dados de exemplo: ' + e.message);
            }
        } else {
            print('Erro ao inicializar Replica Set:');
            printjson(result);
        }
    }
} catch (e) {
    print('Erro durante a inicialização: ' + e.message);
}