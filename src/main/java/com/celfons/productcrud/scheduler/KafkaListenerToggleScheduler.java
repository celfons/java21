package com.celfons.productcrud.scheduler;

import com.celfons.productcrud.config.KafkaListenerToggleProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.listener.MessageListenerContainer;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.concurrent.TimeUnit;

/**
 * Scheduled job that polls a Redis key to control Kafka listener containers.
 * Checks Redis every configured interval and starts/stops all Kafka listeners based on the value.
 */
@Component
public class KafkaListenerToggleScheduler {

    private static final Logger log = LoggerFactory.getLogger(KafkaListenerToggleScheduler.class);

    private final StringRedisTemplate redisTemplate;
    private final KafkaListenerEndpointRegistry registry;
    private final KafkaListenerToggleProperties properties;

    // Track last effective state to detect changes
    private Boolean lastEffectiveState = null;

    public KafkaListenerToggleScheduler(
            StringRedisTemplate redisTemplate,
            KafkaListenerEndpointRegistry registry,
            KafkaListenerToggleProperties properties) {
        this.redisTemplate = redisTemplate;
        this.registry = registry;
        this.properties = properties;
    }

    /**
     * Poll Redis key and control Kafka listeners based on value.
     * Only acts when the effective value changes from the last known state.
     */
    @Scheduled(fixedDelayString = "#{@kafkaListenerToggleProperties.pollInterval.toMillis()}", 
               timeUnit = TimeUnit.MILLISECONDS)
    public void pollAndToggleListeners() {
        try {
            // Get value from Redis
            String redisValue = redisTemplate.opsForValue().get(properties.getRedisKey());
            
            // Parse the value and apply default if needed
            boolean effectiveValue = parseRedisValue(redisValue);
            
            // Only act if value has changed
            if (lastEffectiveState == null || lastEffectiveState != effectiveValue) {
                boolean oldState = (lastEffectiveState != null) ? lastEffectiveState : effectiveValue;
                lastEffectiveState = effectiveValue;
                
                // Get all listener containers
                Collection<MessageListenerContainer> containers = registry.getAllListenerContainers();
                
                if (containers.isEmpty()) {
                    log.debug("No Kafka listener containers found to toggle");
                    return;
                }
                
                // Start or stop all containers based on effective value
                if (effectiveValue) {
                    startAllContainers(containers);
                } else {
                    stopAllContainers(containers);
                }
                
                log.info("Kafka listeners toggled: key={}, {}->{}enabled, containers affected={}",
                        properties.getRedisKey(),
                        oldState == effectiveValue ? "" : (oldState ? "enabled->" : "disabled->"),
                        effectiveValue ? "" : "dis",
                        containers.size());
            }
        } catch (Exception e) {
            log.error("Error polling Redis key '{}' for Kafka listener toggle: {}", 
                    properties.getRedisKey(), e.getMessage(), e);
        }
    }

    /**
     * Parse Redis value to boolean. Returns default value if:
     * - value is null (key doesn't exist)
     * - value is blank
     * - value is not "true" or "false" (case-insensitive)
     */
    private boolean parseRedisValue(String value) {
        if (value == null || value.isBlank()) {
            log.debug("Redis key '{}' not found or blank, using default: {}", 
                    properties.getRedisKey(), properties.isDefaultValue());
            return properties.isDefaultValue();
        }
        
        String trimmedValue = value.trim().toLowerCase();
        if ("true".equals(trimmedValue)) {
            return true;
        } else if ("false".equals(trimmedValue)) {
            return false;
        } else {
            log.warn("Redis key '{}' has unparseable value '{}', using default: {}", 
                    properties.getRedisKey(), value, properties.isDefaultValue());
            return properties.isDefaultValue();
        }
    }

    /**
     * Start all Kafka listener containers.
     */
    private void startAllContainers(Collection<MessageListenerContainer> containers) {
        for (MessageListenerContainer container : containers) {
            if (!container.isRunning()) {
                container.start();
                log.debug("Started Kafka listener container: {}", container.getListenerId());
            }
        }
    }

    /**
     * Stop all Kafka listener containers.
     */
    private void stopAllContainers(Collection<MessageListenerContainer> containers) {
        for (MessageListenerContainer container : containers) {
            if (container.isRunning()) {
                container.stop();
                log.debug("Stopped Kafka listener container: {}", container.getListenerId());
            }
        }
    }
}
