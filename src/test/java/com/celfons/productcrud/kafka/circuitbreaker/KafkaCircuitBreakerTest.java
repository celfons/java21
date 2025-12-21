package com.celfons.productcrud.kafka.circuitbreaker;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.listener.MessageListenerContainer;

import java.time.Clock;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for KafkaCircuitBreaker.
 */
@ExtendWith(MockitoExtension.class)
class KafkaCircuitBreakerTest {
    
    @Mock
    private KafkaListenerEndpointRegistry registry;
    
    @Mock
    private MessageListenerContainer container1;
    
    @Mock
    private MessageListenerContainer container2;
    
    private TopicFailureTracker failureTracker;
    private TopicContainerMapping containerMapping;
    private KafkaCircuitBreaker circuitBreaker;
    
    @BeforeEach
    void setUp() {
        failureTracker = new TopicFailureTracker(Clock.systemUTC());
        containerMapping = new TopicContainerMapping(registry);
        circuitBreaker = new KafkaCircuitBreaker(failureTracker, containerMapping, registry);
    }
    
    @Test
    void testRecordFailure_BelowThreshold_DoesNotStopContainer() {
        String topic = "test-topic";
        String containerId = "test-container";
        
        // Setup container mapping
        containerMapping.registerMapping(topic, containerId);
        
        // Record 9 failures (below threshold)
        for (int i = 0; i < 9; i++) {
            circuitBreaker.recordFailure(topic);
        }
        
        // No container interaction needed since threshold not reached
        // This is just testing the failure tracking
    }
    
    @Test
    void testRecordFailure_AtThreshold_StopsContainer() {
        String topic = "test-topic";
        String containerId = "test-container";
        
        // Setup container mapping
        containerMapping.registerMapping(topic, containerId);
        when(registry.getListenerContainer(containerId)).thenReturn(container1);
        when(container1.isRunning()).thenReturn(true);
        
        // Record 10 failures (at threshold)
        for (int i = 0; i < 10; i++) {
            circuitBreaker.recordFailure(topic);
        }
        
        // Container should be stopped exactly once
        verify(container1, times(1)).stop();
    }
    
    @Test
    void testRecordFailure_StopsMultipleContainersForSameTopic() {
        String topic = "test-topic";
        String containerId1 = "container-1";
        String containerId2 = "container-2";
        
        // Setup container mapping - both containers subscribe to the same topic
        containerMapping.registerMapping(topic, containerId1);
        containerMapping.registerMapping(topic, containerId2);
        when(registry.getListenerContainer(containerId1)).thenReturn(container1);
        when(registry.getListenerContainer(containerId2)).thenReturn(container2);
        when(container1.isRunning()).thenReturn(true);
        when(container2.isRunning()).thenReturn(true);
        
        // Record 10 failures to trip circuit
        for (int i = 0; i < 10; i++) {
            circuitBreaker.recordFailure(topic);
        }
        
        // Both containers should be stopped
        verify(container1, times(1)).stop();
        verify(container2, times(1)).stop();
    }
    
    @Test
    void testRecordFailure_DoesNotStopAlreadyStoppedContainer() {
        String topic = "test-topic";
        String containerId = "test-container";
        
        // Setup container mapping
        containerMapping.registerMapping(topic, containerId);
        when(registry.getListenerContainer(containerId)).thenReturn(container1);
        when(container1.isRunning()).thenReturn(false); // Container already stopped
        
        // Record 10 failures to trip circuit
        for (int i = 0; i < 10; i++) {
            circuitBreaker.recordFailure(topic);
        }
        
        // Stop should not be called on already-stopped container
        verify(container1, never()).stop();
    }
    
    @Test
    void testRecordSuccess_ResetsFailureCount() {
        String topic = "test-topic";
        
        // Record some failures
        for (int i = 0; i < 5; i++) {
            circuitBreaker.recordFailure(topic);
        }
        
        assertEquals(5, circuitBreaker.getFailureCount(topic));
        
        // Record success
        circuitBreaker.recordSuccess(topic);
        
        // Failure count should be reset
        assertEquals(0, circuitBreaker.getFailureCount(topic));
    }
    
    @Test
    void testRecordFailure_NoContainersRegistered_LogsWarning() {
        String topic = "unknown-topic";
        
        // No container mapping for this topic
        // Record 10 failures to trip circuit
        for (int i = 0; i < 10; i++) {
            circuitBreaker.recordFailure(topic);
        }
        
        // Should not throw exception, just log warning
        // No containers to verify since none were set up
    }
    
    @Test
    void testRecordFailure_ContainerNotFoundInRegistry_LogsWarning() {
        String topic = "test-topic";
        String containerId = "test-container";
        
        // Setup mapping but container not in registry
        containerMapping.registerMapping(topic, containerId);
        when(registry.getListenerContainer(containerId)).thenReturn(null);
        
        // Record 10 failures to trip circuit
        for (int i = 0; i < 10; i++) {
            circuitBreaker.recordFailure(topic);
        }
        
        // Should not throw exception, just log warning
    }
    
    @Test
    void testRecordFailure_StopContainerThrowsException_HandlesGracefully() {
        String topic = "test-topic";
        String containerId = "test-container";
        
        // Setup container mapping
        containerMapping.registerMapping(topic, containerId);
        when(registry.getListenerContainer(containerId)).thenReturn(container1);
        when(container1.isRunning()).thenReturn(true);
        doThrow(new RuntimeException("Stop failed")).when(container1).stop();
        
        // Record 10 failures to trip circuit
        for (int i = 0; i < 10; i++) {
            circuitBreaker.recordFailure(topic);
        }
        
        // Should not propagate exception
        verify(container1, times(1)).stop();
    }
}
