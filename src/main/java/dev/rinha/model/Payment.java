package dev.rinha.model;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Internal payment record for storing processed payments.
 */
public record Payment(
    UUID correlationId,
    BigDecimal amount,
    ProcessorType processor,
    Instant processedAt
) {
    
    public enum ProcessorType {
        DEFAULT, FALLBACK
    }
}