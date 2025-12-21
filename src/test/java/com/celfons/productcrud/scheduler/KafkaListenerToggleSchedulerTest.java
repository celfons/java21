package com.celfons.productcrud.scheduler;

import com.celfons.productcrud.config.KafkaListenerToggleProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.listener.MessageListenerContainer;

import java.time.Duration;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.mockito.Mockito.*;

/**
 * Unit tests for KafkaListenerToggleScheduler.
 * Tests the logic of polling Redis and controlling Kafka listeners.
 */
class KafkaListenerToggleSchedulerTest {

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @Mock
    private KafkaListenerEndpointRegistry registry;

    @Mock
    private MessageListenerContainer container1;

    @Mock
    private MessageListenerContainer container2;

    private KafkaListenerToggleProperties properties;

    private KafkaListenerToggleScheduler scheduler;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        
        properties = new KafkaListenerToggleProperties();
        properties.setRedisKey("test:key");
        properties.setDefaultValue(true);
        properties.setPollInterval(Duration.ofSeconds(5));
        
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        
        scheduler = new KafkaListenerToggleScheduler(redisTemplate, registry, properties);
    }

    @Test
    void pollAndToggleListeners_RedisKeyNotFound_UsesDefaultTrue() {
        // Arrange
        when(valueOperations.get(properties.getRedisKey())).thenReturn(null);
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1, container2));
        when(container1.isRunning()).thenReturn(false);
        when(container2.isRunning()).thenReturn(false);

        // Act
        scheduler.pollAndToggleListeners();

        // Assert
        verify(container1).start();
        verify(container2).start();
        verify(container1, never()).stop();
        verify(container2, never()).stop();
    }

    @Test
    void pollAndToggleListeners_RedisKeyTrue_StartsContainers() {
        // Arrange
        when(valueOperations.get(properties.getRedisKey())).thenReturn("true");
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1, container2));
        when(container1.isRunning()).thenReturn(false);
        when(container2.isRunning()).thenReturn(false);

        // Act
        scheduler.pollAndToggleListeners();

        // Assert
        verify(container1).start();
        verify(container2).start();
        verify(container1, never()).stop();
        verify(container2, never()).stop();
    }

    @Test
    void pollAndToggleListeners_RedisKeyFalse_StopsContainers() {
        // Arrange
        when(valueOperations.get(properties.getRedisKey())).thenReturn("false");
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1, container2));
        when(container1.isRunning()).thenReturn(true);
        when(container2.isRunning()).thenReturn(true);

        // Act
        scheduler.pollAndToggleListeners();

        // Assert
        verify(container1).stop();
        verify(container2).stop();
        verify(container1, never()).start();
        verify(container2, never()).start();
    }

    @Test
    void pollAndToggleListeners_RedisKeyCaseInsensitive_True() {
        // Arrange
        when(valueOperations.get(properties.getRedisKey())).thenReturn("TRUE");
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1));
        when(container1.isRunning()).thenReturn(false);

        // Act
        scheduler.pollAndToggleListeners();

        // Assert
        verify(container1).start();
        verify(container1, never()).stop();
    }

    @Test
    void pollAndToggleListeners_RedisKeyCaseInsensitive_False() {
        // Arrange
        when(valueOperations.get(properties.getRedisKey())).thenReturn("False");
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1));
        when(container1.isRunning()).thenReturn(true);

        // Act
        scheduler.pollAndToggleListeners();

        // Assert
        verify(container1).stop();
        verify(container1, never()).start();
    }

    @Test
    void pollAndToggleListeners_RedisKeyBlank_UsesDefault() {
        // Arrange
        when(valueOperations.get(properties.getRedisKey())).thenReturn("  ");
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1));
        when(container1.isRunning()).thenReturn(false);

        // Act
        scheduler.pollAndToggleListeners();

        // Assert
        verify(container1).start();
        verify(container1, never()).stop();
    }

    @Test
    void pollAndToggleListeners_RedisKeyUnparseable_UsesDefault() {
        // Arrange
        when(valueOperations.get(properties.getRedisKey())).thenReturn("invalid");
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1));
        when(container1.isRunning()).thenReturn(false);

        // Act
        scheduler.pollAndToggleListeners();

        // Assert
        verify(container1).start();
        verify(container1, never()).stop();
    }

    @Test
    void pollAndToggleListeners_NoContainers_HandlesGracefully() {
        // Arrange
        when(valueOperations.get(properties.getRedisKey())).thenReturn("true");
        when(registry.getAllListenerContainers()).thenReturn(Collections.emptyList());

        // Act
        scheduler.pollAndToggleListeners();

        // Assert - should not throw exception
        verify(registry).getAllListenerContainers();
    }

    @Test
    void pollAndToggleListeners_ValueUnchanged_DoesNotToggle() {
        // Arrange
        when(valueOperations.get(properties.getRedisKey())).thenReturn("true");
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1));
        when(container1.isRunning()).thenReturn(false);

        // Act - first call
        scheduler.pollAndToggleListeners();

        // Assert - first call should start container
        verify(container1, times(1)).start();
        verify(container1, never()).stop();

        // Reset mocks for second call
        reset(container1, registry);
        when(valueOperations.get(properties.getRedisKey())).thenReturn("true");
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1));

        // Act - second call with same value
        scheduler.pollAndToggleListeners();

        // Assert - second call should not toggle anything
        verify(container1, never()).start();
        verify(container1, never()).stop();
    }

    @Test
    void pollAndToggleListeners_ValueChanged_TogglesOnce() {
        // Arrange
        when(valueOperations.get(properties.getRedisKey())).thenReturn("true");
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1));
        when(container1.isRunning()).thenReturn(false);

        // Act - first call with true
        scheduler.pollAndToggleListeners();

        // Assert - should start container
        verify(container1, times(1)).start();
        verify(container1, never()).stop();

        // Reset mocks for second call
        reset(container1, registry);
        when(valueOperations.get(properties.getRedisKey())).thenReturn("false");
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1));
        when(container1.isRunning()).thenReturn(true);

        // Act - second call with false
        scheduler.pollAndToggleListeners();

        // Assert - should stop container
        verify(container1, never()).start();
        verify(container1, times(1)).stop();
    }

    @Test
    void pollAndToggleListeners_DefaultFalse_StopsContainersWhenKeyMissing() {
        // Arrange
        properties.setDefaultValue(false);
        scheduler = new KafkaListenerToggleScheduler(redisTemplate, registry, properties);
        
        when(valueOperations.get(properties.getRedisKey())).thenReturn(null);
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1));
        when(container1.isRunning()).thenReturn(true);

        // Act
        scheduler.pollAndToggleListeners();

        // Assert
        verify(container1).stop();
        verify(container1, never()).start();
    }

    @Test
    void pollAndToggleListeners_OnlyTogglesRunningContainers() {
        // Arrange
        when(valueOperations.get(properties.getRedisKey())).thenReturn("false");
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1, container2));
        when(container1.isRunning()).thenReturn(true);
        when(container2.isRunning()).thenReturn(false); // already stopped

        // Act
        scheduler.pollAndToggleListeners();

        // Assert
        verify(container1).stop(); // should stop running container
        verify(container2, never()).stop(); // should not stop already stopped container
    }

    @Test
    void pollAndToggleListeners_OnlyStartsStoppedContainers() {
        // Arrange
        when(valueOperations.get(properties.getRedisKey())).thenReturn("true");
        when(registry.getAllListenerContainers()).thenReturn(Arrays.asList(container1, container2));
        when(container1.isRunning()).thenReturn(false);
        when(container2.isRunning()).thenReturn(true); // already running

        // Act
        scheduler.pollAndToggleListeners();

        // Assert
        verify(container1).start(); // should start stopped container
        verify(container2, never()).start(); // should not start already running container
    }
}
