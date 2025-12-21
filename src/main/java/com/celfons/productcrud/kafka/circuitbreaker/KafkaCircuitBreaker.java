package com.celfons.productcrud.kafka.circuitbreaker;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.listener.MessageListenerContainer;
import org.springframework.stereotype.Component;

import java.util.Set;

/**
 * Circuit breaker for Kafka consumers that stops listener containers when a topic exceeds failure threshold.
 * Works in conjunction with TopicFailureTracker and TopicContainerMapping.
 */
@Component
public class KafkaCircuitBreaker {
    
    private static final Logger logger = LoggerFactory.getLogger(KafkaCircuitBreaker.class);
    
    private final TopicFailureTracker failureTracker;
    private final TopicContainerMapping containerMapping;
    private final KafkaListenerEndpointRegistry registry;
    
    public KafkaCircuitBreaker(
            TopicFailureTracker failureTracker,
            TopicContainerMapping containerMapping,
            KafkaListenerEndpointRegistry registry) {
        this.failureTracker = failureTracker;
        this.containerMapping = containerMapping;
        this.registry = registry;
    }
    
    /**
     * Records a failure for the given topic and trips the circuit if threshold is exceeded.
     * Stops all listener containers that are subscribed to the failing topic.
     * 
     * @param topic the Kafka topic that experienced a failure
     */
    public void recordFailure(String topic) {
        boolean shouldTrip = failureTracker.recordFailure(topic);
        
        if (shouldTrip) {
            tripCircuit(topic);
        }
    }
    
    /**
     * Records a successful processing for the given topic, resetting the failure counter.
     * 
     * @param topic the Kafka topic that was successfully processed
     */
    public void recordSuccess(String topic) {
        failureTracker.recordSuccess(topic);
    }
    
    /**
     * Trips the circuit for the given topic by stopping all affected listener containers.
     * 
     * @param topic the topic that has exceeded the failure threshold
     */
    private void tripCircuit(String topic) {
        Set<String> containerIds = containerMapping.getContainerIdsForTopic(topic);
        
        if (containerIds.isEmpty()) {
            logger.warn("Circuit tripped for topic '{}' but no containers found to stop", topic);
            return;
        }
        
        logger.error("CIRCUIT BREAKER TRIPPED for topic '{}'. Stopping {} container(s): {}", 
                    topic, containerIds.size(), containerIds);
        
        for (String containerId : containerIds) {
            stopContainer(containerId);
        }
    }
    
    /**
     * Stops a listener container by ID if it's running.
     * 
     * @param containerId the container ID to stop
     */
    private void stopContainer(String containerId) {
        MessageListenerContainer container = registry.getListenerContainer(containerId);
        
        if (container == null) {
            logger.warn("Container '{}' not found in registry", containerId);
            return;
        }
        
        if (!container.isRunning()) {
            logger.debug("Container '{}' is already stopped", containerId);
            return;
        }
        
        try {
            logger.warn("Stopping container '{}' due to circuit breaker trip", containerId);
            container.stop();
            logger.info("Container '{}' stopped successfully", containerId);
        } catch (Exception e) {
            logger.error("Failed to stop container '{}'", containerId, e);
        }
    }
    
    /**
     * Gets the current failure count for a topic.
     * 
     * @param topic the Kafka topic
     * @return the number of consecutive failures within the time window
     */
    public int getFailureCount(String topic) {
        return failureTracker.getFailureCount(topic);
    }
}
