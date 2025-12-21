package com.celfons.productcrud.kafka.circuitbreaker;

import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.listener.RecordInterceptor;
import org.springframework.stereotype.Component;

/**
 * Interceptor for Kafka record processing that tracks successful processing.
 * Resets the failure counter when records are successfully processed.
 */
@Component
public class CircuitBreakerRecordInterceptor implements RecordInterceptor<Object, Object> {
    
    private static final Logger logger = LoggerFactory.getLogger(CircuitBreakerRecordInterceptor.class);
    
    private final KafkaCircuitBreaker circuitBreaker;
    
    public CircuitBreakerRecordInterceptor(KafkaCircuitBreaker circuitBreaker) {
        this.circuitBreaker = circuitBreaker;
    }
    
    @Override
    public ConsumerRecord<Object, Object> intercept(ConsumerRecord<Object, Object> record, Consumer<Object, Object> consumer) {
        // This is called before processing - just pass through
        return record;
    }
    
    @Override
    public void success(ConsumerRecord<Object, Object> record, Consumer<Object, Object> consumer) {
        // Called after successful processing
        String topic = record.topic();
        logger.trace("Successfully processed record from topic '{}', partition {}, offset {}", 
                    topic, record.partition(), record.offset());
        
        // Reset failure counter for this topic
        circuitBreaker.recordSuccess(topic);
    }
    
    @Override
    public void failure(ConsumerRecord<Object, Object> record, Exception exception, Consumer<Object, Object> consumer) {
        // Failure handling is done by CircuitBreakerErrorHandler
        // This method is called in addition to the error handler
        logger.trace("Record processing failed for topic '{}', will be handled by error handler", record.topic());
    }
}
