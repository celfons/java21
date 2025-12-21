package com.celfons.productcrud.kafka.circuitbreaker;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Instant;
import java.util.LinkedList;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Tracks consecutive failures per Kafka topic within a rolling time window.
 * Thread-safe implementation for tracking failures and determining when circuit should trip.
 */
@Component
public class TopicFailureTracker {
    
    private static final Logger logger = LoggerFactory.getLogger(TopicFailureTracker.class);
    
    private static final int FAILURE_THRESHOLD = 10;
    private static final long TIME_WINDOW_SECONDS = 60;
    
    private final Map<String, LinkedList<Instant>> topicFailures = new ConcurrentHashMap<>();
    private final Clock clock;
    
    public TopicFailureTracker() {
        this(Clock.systemUTC());
    }
    
    // Constructor for testing with custom clock
    public TopicFailureTracker(Clock clock) {
        this.clock = clock;
    }
    
    /**
     * Records a failure for the given topic.
     * 
     * @param topic the Kafka topic that experienced a failure
     * @return true if the circuit should trip (threshold exceeded), false otherwise
     */
    public synchronized boolean recordFailure(String topic) {
        Instant now = clock.instant();
        LinkedList<Instant> failures = topicFailures.computeIfAbsent(topic, k -> new LinkedList<>());
        
        // Add new failure
        failures.add(now);
        
        // Remove failures outside the time window
        Instant windowStart = now.minusSeconds(TIME_WINDOW_SECONDS);
        failures.removeIf(timestamp -> timestamp.isBefore(windowStart));
        
        int failureCount = failures.size();
        logger.debug("Topic '{}' failure recorded. Current consecutive failures within window: {}", 
                    topic, failureCount);
        
        if (failureCount >= FAILURE_THRESHOLD) {
            logger.warn("Topic '{}' has reached failure threshold: {} consecutive failures within {} seconds", 
                       topic, failureCount, TIME_WINDOW_SECONDS);
            return true;
        }
        
        return false;
    }
    
    /**
     * Resets the failure counter for the given topic after successful processing.
     * 
     * @param topic the Kafka topic that was successfully processed
     */
    public synchronized void recordSuccess(String topic) {
        LinkedList<Instant> failures = topicFailures.get(topic);
        if (failures != null && !failures.isEmpty()) {
            logger.info("Topic '{}' successfully processed. Resetting {} consecutive failures.", 
                       topic, failures.size());
            failures.clear();
        }
    }
    
    /**
     * Gets the current failure count for a topic within the time window.
     * 
     * @param topic the Kafka topic
     * @return the number of consecutive failures within the time window
     */
    public synchronized int getFailureCount(String topic) {
        LinkedList<Instant> failures = topicFailures.get(topic);
        if (failures == null) {
            return 0;
        }
        
        // Clean up old failures
        Instant now = clock.instant();
        Instant windowStart = now.minusSeconds(TIME_WINDOW_SECONDS);
        failures.removeIf(timestamp -> timestamp.isBefore(windowStart));
        
        return failures.size();
    }
    
    /**
     * Clears all tracked failures. Useful for testing.
     */
    public synchronized void reset() {
        topicFailures.clear();
    }
}
