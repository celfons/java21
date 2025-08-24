# Rinha Backend 2025 - Checklist

## 0. Projeto / Build
- [ ] Maven wrapper adicionado
- [ ] pom.xml com deps mínimas (web, validation, actuator slim, redis, native)
- [ ] Perfil native funcionando (mvn -Pnative native:compile)
- [ ] Java 21 + virtual threads habilitados

## 1. Configuração
- [ ] application.properties minimal
- [ ] Variáveis de ambiente mapeadas (PROCESSOR_DEFAULT_URL, PROCESSOR_FALLBACK_URL, REDIS_HOST, REDIS_PORT, MAX_AMOUNT, OPEN_DURATION_MS)
- [ ] Logging reduzido (WARN)

## 2. Domínio / Endpoints
- [ ] POST /payments implementado
- [ ] Idempotência (Redis SETNX payments:cid:<uuid>)
- [ ] Roteamento + fallback + circuit breaker
- [ ] Contabilização somente após sucesso upstream
- [ ] GET /payments-summary (sem intervalo) usa agg:totals
- [ ] GET /payments-summary (com intervalo) agrega buckets por minuto
- [ ] Validação from/to + limite minutos

## 3. Redis
- [ ] Conexão Lettuce configurada
- [ ] Buckets agg:<epochMinute>
- [ ] agg:totals
- [ ] Flush incremental (in-memory -> Redis) a cada 100 ops ou 250ms
- [ ] Expiração de chave de idempotência configurada

## 4. Circuit Breaker / Métricas
- [ ] Estados CLOSED / OPEN / HALF_OPEN
- [ ] Disparo por 3 falhas consecutivas OU p95 > 2 * baseline
- [ ] OPEN_DURATION_MS default 750
- [ ] Janela de latências ring buffer (>=128)
- [ ] Métrica baseline atualizada via health poll

## 5. Health Poll
- [ ] Scheduler 5s consulta /payments/service-health (default e fallback) respeitando limite
- [ ] Atualiza baseline mínima e lastSeenHealth

## 6. HTTP Client
- [ ] java.net.http singleton
- [ ] Timeouts conexão (50ms) e request (80ms configurável)
- [ ] Keep-alive reutilizando conexões

## 7. HAProxy / Infra
- [ ] haproxy.cfg
- [ ] compose.yaml (redis, app1, app2, haproxy)
- [ ] Perfis native / jvm
- [ ] Limites de CPU/Memória

## 8. Docker / Makefile
- [ ] Dockerfile.jvm
- [ ] Dockerfile.native (multi-stage GraalVM)
- [ ] Makefile targets (build-jvm, build-native, docker-jvm, docker-native, up, down, load-test)

## 9. Util / Validação
- [ ] Conversão amount BigDecimal -> long cents
- [ ] Limite MAX_AMOUNT
- [ ] UUID validação leve
- [ ] Erros 400 devidamente retornados

## 10. Documentação
- [ ] README com instruções build/run
- [ ] Desenho ASCII arquitetura
- [ ] Tuning rationale (virtual threads, Redis, circuit breaker)

## 11. Qualidade
- [ ] Teste de carga script (scripts/load.sh)
- [ ] Verificação consistência summary sob carga
- [ ] p99 medido e anotado
