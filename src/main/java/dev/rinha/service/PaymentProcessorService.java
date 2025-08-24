package dev.rinha.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.rinha.dto.PaymentRequest;
import dev.rinha.model.Payment;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

/**
 * Service for communicating with external payment processors.
 */
@Service
public class PaymentProcessorService {
    
    private static final Logger logger = LoggerFactory.getLogger(PaymentProcessorService.class);
    
    private final HttpClient httpClient;
    private final CircuitBreaker circuitBreaker;
    private final ObjectMapper objectMapper;
    
    @Value("${processor.default.url}")
    private String defaultProcessorUrl;
    
    @Value("${processor.fallback.url}")
    private String fallbackProcessorUrl;
    
    @Value("${processor.request-timeout:80ms}")
    private Duration requestTimeout;
    
    public PaymentProcessorService(HttpClient httpClient, CircuitBreaker circuitBreaker, ObjectMapper objectMapper) {
        this.httpClient = httpClient;
        this.circuitBreaker = circuitBreaker;
        this.objectMapper = objectMapper;
    }
    
    /**
     * Process payment using default processor with fallback on failure.
     */
    public Payment processPayment(PaymentRequest request) {
        Payment.ProcessorType usedProcessor;
        
        // Try default processor first if circuit breaker allows
        if (circuitBreaker.canExecute()) {
            try {
                boolean success = sendPaymentRequest(defaultProcessorUrl, request);
                if (success) {
                    circuitBreaker.recordSuccess();
                    usedProcessor = Payment.ProcessorType.DEFAULT;
                    logger.debug("Payment processed successfully with default processor: {}", request.correlationId());
                } else {
                    circuitBreaker.recordFailure();
                    usedProcessor = processWithFallback(request);
                }
            } catch (Exception e) {
                logger.warn("Default processor failed for payment {}: {}", request.correlationId(), e.getMessage());
                circuitBreaker.recordFailure();
                usedProcessor = processWithFallback(request);
            }
        } else {
            logger.debug("Circuit breaker is open, using fallback processor for payment: {}", request.correlationId());
            usedProcessor = processWithFallback(request);
        }
        
        return new Payment(
            request.correlationId(),
            request.amount(),
            usedProcessor,
            Instant.now()
        );
    }
    
    private Payment.ProcessorType processWithFallback(PaymentRequest request) {
        try {
            boolean success = sendPaymentRequest(fallbackProcessorUrl, request);
            if (success) {
                logger.debug("Payment processed successfully with fallback processor: {}", request.correlationId());
                return Payment.ProcessorType.FALLBACK;
            } else {
                logger.error("Fallback processor also failed for payment: {}", request.correlationId());
                throw new RuntimeException("Both processors failed");
            }
        } catch (Exception e) {
            logger.error("Fallback processor failed for payment {}: {}", request.correlationId(), e.getMessage());
            throw new RuntimeException("Both processors failed", e);
        }
    }
    
    private boolean sendPaymentRequest(String processorUrl, PaymentRequest request) throws Exception {
        String requestBody = objectMapper.writeValueAsString(request);
        
        HttpRequest httpRequest = HttpRequest.newBuilder()
                .uri(URI.create(processorUrl + "/payments"))
                .header("Content-Type", "application/json")
                .timeout(requestTimeout)
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();
        
        HttpResponse<String> response = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString());
        
        // Consider 2xx as success
        int statusCode = response.statusCode();
        if (statusCode >= 200 && statusCode < 300) {
            return true;
        } else if (statusCode >= 500) {
            throw new RuntimeException("Server error: " + statusCode);
        } else {
            return false;
        }
    }
}