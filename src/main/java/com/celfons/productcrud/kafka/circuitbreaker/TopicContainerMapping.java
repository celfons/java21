package com.celfons.productcrud.kafka.circuitbreaker;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.listener.MessageListenerContainer;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Maintains a mapping between Kafka topics and their listener container IDs.
 * This allows the circuit breaker to identify which containers to stop when a topic fails.
 */
@Component
public class TopicContainerMapping {
    
    private static final Logger logger = LoggerFactory.getLogger(TopicContainerMapping.class);
    
    private final KafkaListenerEndpointRegistry registry;
    private final Map<String, Set<String>> topicToContainerIds = new ConcurrentHashMap<>();
    
    public TopicContainerMapping(KafkaListenerEndpointRegistry registry) {
        this.registry = registry;
    }
    
    /**
     * Initializes the topic-to-container mapping at startup by inspecting all registered containers.
     */
    @PostConstruct
    public void initialize() {
        logger.info("Initializing topic-to-container mapping...");
        
        for (MessageListenerContainer container : registry.getAllListenerContainers()) {
            String containerId = container.getListenerId();
            String[] topics = container.getContainerProperties().getTopics();
            
            if (topics != null && topics.length > 0) {
                for (String topic : topics) {
                    topicToContainerIds.computeIfAbsent(topic, k -> ConcurrentHashMap.newKeySet())
                                      .add(containerId);
                    logger.debug("Mapped topic '{}' to container '{}'", topic, containerId);
                }
            }
        }
        
        logger.info("Topic-to-container mapping initialized. Total mappings: {}", topicToContainerIds.size());
    }
    
    /**
     * Gets all container IDs that are subscribed to the given topic.
     * 
     * @param topic the Kafka topic
     * @return set of container IDs, or empty set if no containers are subscribed to this topic
     */
    public Set<String> getContainerIdsForTopic(String topic) {
        return topicToContainerIds.getOrDefault(topic, Collections.emptySet());
    }
    
    /**
     * Manually registers a topic-to-container mapping.
     * Useful for dynamic listener registration or testing.
     * 
     * @param topic the Kafka topic
     * @param containerId the container ID
     */
    public void registerMapping(String topic, String containerId) {
        topicToContainerIds.computeIfAbsent(topic, k -> ConcurrentHashMap.newKeySet())
                          .add(containerId);
        logger.debug("Manually registered mapping: topic '{}' -> container '{}'", topic, containerId);
    }
    
    /**
     * Gets all topics currently mapped to containers.
     * 
     * @return set of all topics
     */
    public Set<String> getAllTopics() {
        return topicToContainerIds.keySet();
    }
}
