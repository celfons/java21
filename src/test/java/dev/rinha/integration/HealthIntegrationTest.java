package dev.rinha.integration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration test for health endpoint.
 * Verifies the application starts properly and health endpoint responds correctly.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(properties = {
    "spring.data.redis.host=localhost",
    "spring.data.redis.port=6370",  // Use different port to avoid conflicts
    "processor.default.url=http://localhost:8081",
    "processor.fallback.url=http://localhost:8082"
})
class HealthIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void healthEndpointShouldBeAccessible() {
        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(
            "http://localhost:" + port + "/actuator/health", 
            String.class
        );

        // Assert - Should return either 200 (UP) or 503 (DOWN), but should be accessible
        assertThat(response.getStatusCode()).isIn(HttpStatus.OK, HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody()).isNotEmpty();
        // The response should contain status field
        assertThat(response.getBody()).containsAnyOf("\"status\":\"UP\"", "\"status\":\"DOWN\"");
    }

    @Test
    void healthEndpointShouldReturnJsonFormat() {
        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(
            "http://localhost:" + port + "/actuator/health", 
            String.class
        );

        // Assert - Should return JSON format regardless of status
        assertThat(response.getBody()).contains("\"status\":");
        assertThat(response.getBody()).startsWith("{");
        assertThat(response.getBody()).endsWith("}");
    }
}