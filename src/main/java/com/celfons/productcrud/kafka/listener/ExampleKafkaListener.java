package com.celfons.productcrud.kafka.listener;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Example Kafka listener demonstrating circuit breaker integration.
 * This listener is protected by the automatic circuit breaker.
 * If it fails 10 consecutive times within 60 seconds, the container will be stopped automatically.
 */
@Component
public class ExampleKafkaListener {
    
    private static final Logger logger = LoggerFactory.getLogger(ExampleKafkaListener.class);
    
    /**
     * Example listener for order events.
     * Circuit breaker monitors this listener and will stop the container if failures exceed threshold.
     * 
     * @param message the order message
     */
    @KafkaListener(id = "ordersListener", topics = "orders", autoStartup = "${kafka.listener.orders.enabled:false}")
    public void handleOrder(String message) {
        logger.info("Processing order: {}", message);
        
        // Your business logic here
        // If this throws an exception 10 times consecutively within 60s,
        // the circuit breaker will stop this listener container
        
        logger.debug("Order processed successfully: {}", message);
    }
    
    /**
     * Example listener for payment events.
     * This listener subscribes to multiple topics.
     * If either topic trips the circuit breaker, this entire container will be stopped.
     * 
     * @param message the payment message
     */
    @KafkaListener(id = "paymentsListener", topics = {"payments", "refunds"}, autoStartup = "${kafka.listener.payments.enabled:false}")
    public void handlePayment(String message) {
        logger.info("Processing payment/refund: {}", message);
        
        // Your business logic here
        // Circuit breaker tracks failures per topic independently
        // But stops the entire container if any subscribed topic trips
        
        logger.debug("Payment/refund processed successfully: {}", message);
    }
    
    /**
     * Example listener for notification events.
     * Demonstrates independent circuit breaking per listener.
     * 
     * @param message the notification message
     */
    @KafkaListener(id = "notificationsListener", topics = "notifications", autoStartup = "${kafka.listener.notifications.enabled:false}")
    public void handleNotification(String message) {
        logger.info("Processing notification: {}", message);
        
        // This listener has its own circuit breaker state
        // Failures here don't affect other listeners
        
        logger.debug("Notification sent successfully: {}", message);
    }
}
