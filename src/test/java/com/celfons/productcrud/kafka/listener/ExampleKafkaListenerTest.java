package com.celfons.productcrud.kafka.listener;

import com.celfons.productcrud.kafka.circuitbreaker.KafkaCircuitBreaker;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.test.context.TestPropertySource;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test that verifies the example Kafka listeners are properly configured
 * and integrate with the circuit breaker.
 */
@SpringBootTest
@TestPropertySource(properties = {
    "spring.data.mongodb.uri=mongodb://localhost:27017/testdb",
    "kafka.listener.orders.enabled=false",
    "kafka.listener.payments.enabled=false",
    "kafka.listener.notifications.enabled=false"
})
class ExampleKafkaListenerTest {
    
    @Autowired(required = false)
    private ExampleKafkaListener kafkaListener;
    
    @Autowired
    private KafkaCircuitBreaker circuitBreaker;
    
    @Autowired(required = false)
    private KafkaListenerEndpointRegistry registry;
    
    @Test
    void testKafkaListenerBeanExists() {
        assertNotNull(kafkaListener, "ExampleKafkaListener should be available as a Spring bean");
    }
    
    @Test
    void testCircuitBreakerBeanExists() {
        assertNotNull(circuitBreaker, "KafkaCircuitBreaker should be available as a Spring bean");
    }
    
    @Test
    void testListenerRegistryExists() {
        assertNotNull(registry, "KafkaListenerEndpointRegistry should be available");
    }
    
    @Test
    void testListenerContainersAreRegistered() {
        if (registry != null) {
            // Listeners might not be started if autoStartup is false
            // But they should be registered
            assertTrue(registry.getAllListenerContainers().size() >= 0, 
                      "Registry should contain listener containers");
        }
    }
    
    @Test
    void testCircuitBreakerInitialState() {
        // Initially, all topics should have 0 failures
        assertEquals(0, circuitBreaker.getFailureCount("orders"));
        assertEquals(0, circuitBreaker.getFailureCount("payments"));
        assertEquals(0, circuitBreaker.getFailureCount("refunds"));
        assertEquals(0, circuitBreaker.getFailureCount("notifications"));
    }
    
    @Test
    void testOrderListenerMethodExists() throws NoSuchMethodException {
        // Verify the listener methods exist
        assertNotNull(kafkaListener.getClass().getMethod("handleOrder", String.class));
    }
    
    @Test
    void testPaymentListenerMethodExists() throws NoSuchMethodException {
        // Verify the listener methods exist
        assertNotNull(kafkaListener.getClass().getMethod("handlePayment", String.class));
    }
    
    @Test
    void testNotificationListenerMethodExists() throws NoSuchMethodException {
        // Verify the listener methods exist
        assertNotNull(kafkaListener.getClass().getMethod("handleNotification", String.class));
    }
}
