package com.celfons.productcrud.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * Configuration properties for Kafka listener toggle feature.
 * Allows controlling Kafka listeners via a Redis key.
 */
@Component
@ConfigurationProperties(prefix = "app.kafka.listeners.enabled")
public class KafkaListenerToggleProperties {

    /**
     * Redis key to check for enabling/disabling Kafka listeners.
     * Value should be "true" or "false" (case-insensitive).
     */
    private String redisKey = "kafka:listeners:enabled";

    /**
     * Default value to use when Redis key doesn't exist or is unparseable.
     */
    private boolean defaultValue = true;

    /**
     * Interval for polling the Redis key.
     */
    private Duration pollInterval = Duration.ofSeconds(5);

    public String getRedisKey() {
        return redisKey;
    }

    public void setRedisKey(String redisKey) {
        this.redisKey = redisKey;
    }

    public boolean isDefaultValue() {
        return defaultValue;
    }

    public void setDefaultValue(boolean defaultValue) {
        this.defaultValue = defaultValue;
    }

    public Duration getPollInterval() {
        return pollInterval;
    }

    public void setPollInterval(Duration pollInterval) {
        this.pollInterval = pollInterval;
    }
}
