package dev.rinha.controller;

import dev.rinha.dto.PaymentRequest;
import dev.rinha.dto.PaymentsSummaryResponse;
import dev.rinha.service.PaymentService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

/**
 * REST Controller for payment operations.
 * Handles HTTP requests for the Rinha de Backend 2025 challenge.
 */
@RestController
public class PaymentController {
    
    private static final Logger logger = LoggerFactory.getLogger(PaymentController.class);
    
    private final PaymentService paymentService;
    
    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }
    
    /**
     * Process a payment with idempotency.
     * POST /payments
     */
    @PostMapping("/payments")
    public ResponseEntity<Void> processPayment(@Valid @RequestBody PaymentRequest request) {
        logger.debug("Processing payment: {}", request.correlationId());
        
        try {
            paymentService.processPayment(request);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            logger.error("Payment processing failed", e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    /**
     * Get payments summary for a time range.
     * GET /payments-summary?from={ISO8601}&to={ISO8601}
     */
    @GetMapping("/payments-summary")
    public ResponseEntity<PaymentsSummaryResponse> getPaymentsSummary(
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to) {
        
        try {
            Instant fromInstant = from != null ? parseInstant(from) : null;
            Instant toInstant = to != null ? parseInstant(to) : null;
            
            PaymentsSummaryResponse summary = paymentService.getPaymentsSummary(fromInstant, toInstant);
            return ResponseEntity.ok(summary);
            
        } catch (Exception e) {
            logger.error("Failed to get payments summary", e);
            return ResponseEntity.badRequest().build();
        }
    }
    
    private Instant parseInstant(String value) {
        try {
            // Try parsing as ISO8601 first
            return Instant.parse(value);
        } catch (Exception e) {
            try {
                // Try parsing as epoch timestamp
                return Instant.ofEpochSecond(Long.parseLong(value));
            } catch (Exception ex) {
                throw new IllegalArgumentException("Invalid timestamp format: " + value);
            }
        }
    }
}