package com.celfons.productcrud.kafka.circuitbreaker;

import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.listener.CommonErrorHandler;
import org.springframework.kafka.listener.MessageListenerContainer;
import org.springframework.stereotype.Component;

/**
 * Error handler for Kafka listeners that integrates with the circuit breaker.
 * Records failures per topic and triggers circuit breaking when threshold is exceeded.
 */
@Component
public class CircuitBreakerErrorHandler implements CommonErrorHandler {
    
    private static final Logger logger = LoggerFactory.getLogger(CircuitBreakerErrorHandler.class);
    
    private final KafkaCircuitBreaker circuitBreaker;
    
    public CircuitBreakerErrorHandler(KafkaCircuitBreaker circuitBreaker) {
        this.circuitBreaker = circuitBreaker;
    }
    
    @Override
    public boolean handleOne(
            Exception thrownException,
            ConsumerRecord<?, ?> record,
            Consumer<?, ?> consumer,
            MessageListenerContainer container) {
        
        String topic = record.topic();
        logger.error("Error processing record from topic '{}', partition {}, offset {}: {}", 
                    topic, record.partition(), record.offset(), thrownException.getMessage(), thrownException);
        
        // Record the failure in the circuit breaker
        circuitBreaker.recordFailure(topic);
        
        // Return false to indicate the error was not fully handled (let default error handling proceed)
        return false;
    }
    
    @Override
    public void handleBatch(
            Exception thrownException,
            org.apache.kafka.clients.consumer.ConsumerRecords<?, ?> data,
            Consumer<?, ?> consumer,
            MessageListenerContainer container,
            Runnable invokeListener) {
        
        // For batch processing, record failure for all unique topics in the batch
        if (data != null && !data.isEmpty()) {
            data.partitions().forEach(topicPartition -> {
                String topic = topicPartition.topic();
                logger.error("Error processing batch from topic '{}', partition {}: {}", 
                           topic, topicPartition.partition(), thrownException.getMessage(), thrownException);
                circuitBreaker.recordFailure(topic);
            });
        } else {
            logger.error("Error processing batch (no records available): {}", 
                        thrownException.getMessage(), thrownException);
        }
    }
}
