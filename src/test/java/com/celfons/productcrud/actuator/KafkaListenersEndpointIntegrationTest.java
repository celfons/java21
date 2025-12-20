package com.celfons.productcrud.actuator;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.listener.MessageListenerContainer;
import org.springframework.test.context.TestPropertySource;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration test for Kafka Listeners Actuator endpoint.
 * Tests the ability to list, enable, and disable Kafka listener containers.
 */
@SpringBootTest(
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
    classes = {com.celfons.productcrud.ProductCrudApplication.class, KafkaListenersEndpointIntegrationTest.TestKafkaListener.class}
)
@TestPropertySource(properties = {
    "spring.data.mongodb.uri=mongodb://localhost:27017/testdb",
    "management.health.mongo.enabled=false",
    "spring.kafka.bootstrap-servers=localhost:9092",
    "spring.kafka.consumer.auto-offset-reset=earliest",
    "spring.kafka.consumer.group-id=test-group"
})
class KafkaListenersEndpointIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private KafkaListenerEndpointRegistry registry;

    @Test
    void kafkaListenersEndpointShouldBeAccessible() {
        // Act
        ResponseEntity<Map> response = restTemplate.getForEntity(
            "http://localhost:" + port + "/actuator/kafka-listeners",
            Map.class
        );

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody()).containsKeys("listeners", "totalCount", "runningCount", "stoppedCount");
    }

    @Test
    void listListenersShouldReturnCorrectStructure() {
        // Act
        ResponseEntity<Map> response = restTemplate.getForEntity(
            "http://localhost:" + port + "/actuator/kafka-listeners",
            Map.class
        );

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        Map<String, Object> body = response.getBody();
        assertThat(body).isNotNull();
        
        // Check that we have at least our test listener
        assertThat(body.get("totalCount")).isNotNull();
        assertThat(body.get("runningCount")).isNotNull();
        assertThat(body.get("stoppedCount")).isNotNull();
        assertThat(body.get("listeners")).isInstanceOf(java.util.List.class);
    }

    @Test
    void disableOperationShouldStopAllListeners() {
        // Arrange - Ensure at least one listener is running
        for (MessageListenerContainer container : registry.getAllListenerContainers()) {
            if (!container.isRunning()) {
                container.start();
            }
        }

        // Act
        ResponseEntity<Map> response = restTemplate.postForEntity(
            "http://localhost:" + port + "/actuator/kafka-listeners/disable",
            null,
            Map.class
        );

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        Map<String, Object> body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body).containsKeys("listeners", "action", "message", "disabledListeners");
        assertThat(body.get("action")).isEqualTo("disable");
        
        // Verify all containers are stopped
        for (MessageListenerContainer container : registry.getAllListenerContainers()) {
            assertThat(container.isRunning()).isFalse();
        }
    }

    @Test
    void enableOperationShouldStartAllListeners() {
        // Arrange - Stop all listeners first
        for (MessageListenerContainer container : registry.getAllListenerContainers()) {
            if (container.isRunning()) {
                container.stop();
            }
        }

        // Act
        ResponseEntity<Map> response = restTemplate.postForEntity(
            "http://localhost:" + port + "/actuator/kafka-listeners/enable",
            null,
            Map.class
        );

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        Map<String, Object> body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body).containsKeys("listeners", "action", "message", "enabledListeners");
        assertThat(body.get("action")).isEqualTo("enable");
        
        // Verify all containers are running
        for (MessageListenerContainer container : registry.getAllListenerContainers()) {
            assertThat(container.isRunning()).isTrue();
        }
    }

    @Test
    void disableAndEnableOperationsShouldToggleListenerState() {
        // Arrange - Start with all listeners running
        for (MessageListenerContainer container : registry.getAllListenerContainers()) {
            if (!container.isRunning()) {
                container.start();
            }
        }

        // Act - Disable all listeners
        restTemplate.postForEntity(
            "http://localhost:" + port + "/actuator/kafka-listeners/disable",
            null,
            Map.class
        );

        // Assert - All should be stopped
        for (MessageListenerContainer container : registry.getAllListenerContainers()) {
            assertThat(container.isRunning()).isFalse();
        }

        // Act - Enable all listeners again
        restTemplate.postForEntity(
            "http://localhost:" + port + "/actuator/kafka-listeners/enable",
            null,
            Map.class
        );

        // Assert - All should be running
        for (MessageListenerContainer container : registry.getAllListenerContainers()) {
            assertThat(container.isRunning()).isTrue();
        }
    }

    /**
     * Test Kafka listener component to ensure we have at least one listener registered.
     * This listener is auto-started by default.
     */
    @org.springframework.stereotype.Component
    static class TestKafkaListener {
        
        @KafkaListener(id = "test-listener", topics = "test-topic", autoStartup = "true")
        public void listen(String message) {
            // This listener doesn't need to do anything for the test
            // It just needs to be registered
        }
    }
}
