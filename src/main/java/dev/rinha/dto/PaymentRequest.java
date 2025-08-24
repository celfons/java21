package dev.rinha.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * Payment request DTO for POST /payments endpoint.
 */
public record PaymentRequest(
    @NotNull(message = "correlationId is required")
    UUID correlationId,
    
    @NotNull(message = "amount is required")
    @Positive(message = "amount must be positive")
    BigDecimal amount
) {
}