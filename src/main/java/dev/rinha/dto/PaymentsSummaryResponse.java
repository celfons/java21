package dev.rinha.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Payment summary response DTO for GET /payments-summary endpoint.
 */
public record PaymentsSummaryResponse(
    @JsonProperty("totalAmountDefault")
    String totalAmountDefault,
    
    @JsonProperty("totalCountDefault")
    long totalCountDefault,
    
    @JsonProperty("totalAmountFallback")
    String totalAmountFallback,
    
    @JsonProperty("totalCountFallback")
    long totalCountFallback,
    
    @JsonProperty("interval")
    Interval interval
) {
    
    public record Interval(
        String from,
        String to
    ) {}
}