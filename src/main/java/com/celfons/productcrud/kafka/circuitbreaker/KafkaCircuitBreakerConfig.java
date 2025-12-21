package com.celfons.productcrud.kafka.circuitbreaker;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.core.ConsumerFactory;

/**
 * Configuration for Kafka circuit breaker functionality.
 * Automatically configures error handling and record interceptors for circuit breaking.
 */
@Configuration
@EnableKafka
@ConditionalOnClass(name = "org.springframework.kafka.annotation.KafkaListener")
public class KafkaCircuitBreakerConfig {
    
    private static final Logger logger = LoggerFactory.getLogger(KafkaCircuitBreakerConfig.class);
    
    private final CircuitBreakerErrorHandler errorHandler;
    private final CircuitBreakerRecordInterceptor recordInterceptor;
    
    public KafkaCircuitBreakerConfig(
            CircuitBreakerErrorHandler errorHandler,
            CircuitBreakerRecordInterceptor recordInterceptor) {
        this.errorHandler = errorHandler;
        this.recordInterceptor = recordInterceptor;
    }
    
    /**
     * Configures the Kafka listener container factory with circuit breaker support.
     * Sets up error handling and record interception for tracking failures and successes.
     */
    @Bean
    public ConcurrentKafkaListenerContainerFactory<Object, Object> kafkaListenerContainerFactory(
            ConsumerFactory<Object, Object> consumerFactory,
            KafkaListenerEndpointRegistry registry) {
        
        ConcurrentKafkaListenerContainerFactory<Object, Object> factory = 
            new ConcurrentKafkaListenerContainerFactory<>();
        
        factory.setConsumerFactory(consumerFactory);
        
        // Set the circuit breaker error handler
        factory.setCommonErrorHandler(errorHandler);
        
        // Set the record interceptor to track successes
        factory.setRecordInterceptor(recordInterceptor);
        
        logger.info("Kafka circuit breaker configured with error handler and record interceptor");
        
        return factory;
    }
}
