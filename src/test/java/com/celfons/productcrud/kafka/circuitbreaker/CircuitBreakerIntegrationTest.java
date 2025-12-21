package com.celfons.productcrud.kafka.circuitbreaker;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.listener.MessageListenerContainer;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Integration test for the circuit breaker components working together.
 */
@ExtendWith(MockitoExtension.class)
class CircuitBreakerIntegrationTest {
    
    @Mock
    private KafkaListenerEndpointRegistry registry;
    
    @Mock
    private MessageListenerContainer container;
    
    private TopicFailureTracker failureTracker;
    private TopicContainerMapping containerMapping;
    private KafkaCircuitBreaker circuitBreaker;
    private CircuitBreakerErrorHandler errorHandler;
    private CircuitBreakerRecordInterceptor recordInterceptor;
    private FakeClock fakeClock;
    
    @BeforeEach
    void setUp() {
        fakeClock = new FakeClock();
        failureTracker = new TopicFailureTracker(fakeClock);
        containerMapping = new TopicContainerMapping(registry);
        circuitBreaker = new KafkaCircuitBreaker(failureTracker, containerMapping, registry);
        errorHandler = new CircuitBreakerErrorHandler(circuitBreaker);
        recordInterceptor = new CircuitBreakerRecordInterceptor(circuitBreaker);
    }
    
    @Test
    void testFullCircuitBreakerFlow_FailuresThenTrip() {
        String topic = "orders";
        String containerId = "ordersListener";
        
        // Setup
        containerMapping.registerMapping(topic, containerId);
        when(registry.getListenerContainer(containerId)).thenReturn(container);
        when(container.isRunning()).thenReturn(true);
        
        // Simulate 9 failures
        for (int i = 0; i < 9; i++) {
            ConsumerRecord<Object, Object> record = createRecord(topic, i);
            errorHandler.handleOne(new RuntimeException("Processing error"), record, null, container);
        }
        
        // Container should still be running
        verify(container, never()).stop();
        assertEquals(9, circuitBreaker.getFailureCount(topic));
        
        // 10th failure should trip the circuit
        ConsumerRecord<Object, Object> record = createRecord(topic, 10);
        errorHandler.handleOne(new RuntimeException("Processing error"), record, null, container);
        
        // Container should be stopped
        verify(container, times(1)).stop();
        assertEquals(10, circuitBreaker.getFailureCount(topic));
    }
    
    @Test
    void testSuccessResetsFailureCount() {
        String topic = "orders";
        
        // Simulate 5 failures
        for (int i = 0; i < 5; i++) {
            ConsumerRecord<Object, Object> record = createRecord(topic, i);
            errorHandler.handleOne(new RuntimeException("Processing error"), record, null, container);
        }
        
        assertEquals(5, circuitBreaker.getFailureCount(topic));
        
        // Simulate successful processing
        ConsumerRecord<Object, Object> successRecord = createRecord(topic, 100);
        recordInterceptor.success(successRecord, null);
        
        // Failure count should be reset
        assertEquals(0, circuitBreaker.getFailureCount(topic));
    }
    
    @Test
    void testTimeWindow_OldFailuresAreIgnored() {
        String topic = "orders";
        
        // Record 5 failures at time 0
        for (int i = 0; i < 5; i++) {
            ConsumerRecord<Object, Object> record = createRecord(topic, i);
            errorHandler.handleOne(new RuntimeException("Processing error"), record, null, container);
        }
        
        assertEquals(5, circuitBreaker.getFailureCount(topic));
        
        // Advance time by 61 seconds (outside 60s window)
        fakeClock.advance(61);
        
        // Old failures should be removed
        assertEquals(0, circuitBreaker.getFailureCount(topic));
        
        // Record 5 more failures
        for (int i = 0; i < 5; i++) {
            ConsumerRecord<Object, Object> record = createRecord(topic, i + 100);
            errorHandler.handleOne(new RuntimeException("Processing error"), record, null, container);
        }
        
        // Should only count new failures
        assertEquals(5, circuitBreaker.getFailureCount(topic));
    }
    
    @Test
    void testMultipleTopics_IndependentCircuitBreakers() {
        String topic1 = "orders";
        String topic2 = "payments";
        String containerId1 = "ordersListener";
        String containerId2 = "paymentsListener";
        
        // Setup
        containerMapping.registerMapping(topic1, containerId1);
        containerMapping.registerMapping(topic2, containerId2);
        
        MessageListenerContainer container1 = mock(MessageListenerContainer.class);
        MessageListenerContainer container2 = mock(MessageListenerContainer.class);
        
        when(registry.getListenerContainer(containerId1)).thenReturn(container1);
        when(container1.isRunning()).thenReturn(true);
        
        // Trip circuit for topic1 only
        for (int i = 0; i < 10; i++) {
            ConsumerRecord<Object, Object> record = createRecord(topic1, i);
            errorHandler.handleOne(new RuntimeException("Processing error"), record, null, container1);
        }
        
        // Record 5 failures for topic2
        for (int i = 0; i < 5; i++) {
            ConsumerRecord<Object, Object> record = createRecord(topic2, i);
            errorHandler.handleOne(new RuntimeException("Processing error"), record, null, container2);
        }
        
        // Only container1 should be stopped
        verify(container1, times(1)).stop();
        
        // Verify failure counts
        assertEquals(10, circuitBreaker.getFailureCount(topic1));
        assertEquals(5, circuitBreaker.getFailureCount(topic2));
    }
    
    private ConsumerRecord<Object, Object> createRecord(String topic, long offset) {
        return new ConsumerRecord<>(topic, 0, offset, null, "test-value");
    }
    
    /**
     * Fake clock implementation for testing time-based logic.
     */
    private static class FakeClock extends Clock {
        private Instant currentTime = Instant.parse("2024-01-01T00:00:00Z");
        
        public void advance(long seconds) {
            currentTime = currentTime.plusSeconds(seconds);
        }
        
        @Override
        public Instant instant() {
            return currentTime;
        }
        
        @Override
        public ZoneId getZone() {
            return ZoneId.of("UTC");
        }
        
        @Override
        public Clock withZone(ZoneId zone) {
            return this;
        }
    }
}
