#!/bin/bash
# Wrapper para detectar docker-compose v1 ou docker compose v2

# Função para detectar versão do docker compose
detect_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    elif docker compose version &> /dev/null; then
        echo "docker compose"
    else
        echo "ERROR: Neither docker-compose nor docker compose found"
        exit 1
    fi
}

# Detectar comando
DOCKER_COMPOSE_CMD=$(detect_docker_compose)

# Executar comando passado como argumentos
if [ "$DOCKER_COMPOSE_CMD" = "ERROR: Neither docker-compose nor docker compose found" ]; then
    echo "$DOCKER_COMPOSE_CMD"
    exit 1
else
    exec $DOCKER_COMPOSE_CMD "$@"
fi