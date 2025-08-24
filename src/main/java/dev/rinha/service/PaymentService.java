package dev.rinha.service;

import dev.rinha.dto.PaymentRequest;
import dev.rinha.dto.PaymentsSummaryResponse;
import dev.rinha.model.Payment;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Set;
import java.util.UUID;

/**
 * Main payment service handling idempotency and aggregation.
 */
@Service
public class PaymentService {
    
    private static final Logger logger = LoggerFactory.getLogger(PaymentService.class);
    private static final String IDEMPOTENCY_KEY_PREFIX = "payments:cid:";
    private static final String AGGREGATION_KEY_PREFIX = "payments:agg:";
    private static final Duration IDEMPOTENCY_TTL = Duration.ofMinutes(30);
    
    private final RedisTemplate<String, Object> redisTemplate;
    private final PaymentProcessorService processorService;
    
    public PaymentService(RedisTemplate<String, Object> redisTemplate, PaymentProcessorService processorService) {
        this.redisTemplate = redisTemplate;
        this.processorService = processorService;
    }
    
    /**
     * Process payment with idempotency guarantee.
     */
    public void processPayment(PaymentRequest request) {
        String idempotencyKey = IDEMPOTENCY_KEY_PREFIX + request.correlationId();
        
        // Check idempotency using Redis SETNX
        Boolean wasSet = redisTemplate.opsForValue().setIfAbsent(idempotencyKey, "processing", IDEMPOTENCY_TTL);
        
        if (Boolean.FALSE.equals(wasSet)) {
            logger.debug("Payment already processed (idempotent): {}", request.correlationId());
            return; // Already processed
        }
        
        try {
            // Process payment with external processors
            Payment payment = processorService.processPayment(request);
            
            // Update aggregation counters only after successful processing
            updateAggregation(payment);
            
            // Mark as completed
            redisTemplate.opsForValue().set(idempotencyKey, "completed", IDEMPOTENCY_TTL);
            
            logger.info("Payment processed successfully: {} with processor {}", 
                       request.correlationId(), payment.processor());
            
        } catch (Exception e) {
            // Remove idempotency key on failure to allow retry
            redisTemplate.delete(idempotencyKey);
            logger.error("Payment processing failed: {}", request.correlationId(), e);
            throw new RuntimeException("Payment processing failed", e);
        }
    }
    
    /**
     * Get payments summary for the specified time range.
     */
    public PaymentsSummaryResponse getPaymentsSummary(Instant from, Instant to) {
        // Use provided range or default to current day
        if (from == null || to == null) {
            Instant now = Instant.now();
            from = now.truncatedTo(ChronoUnit.DAYS);
            to = now;
        }
        
        // Get aggregation data from Redis
        long totalCountDefault = getAggregationCount(Payment.ProcessorType.DEFAULT, from, to);
        long totalCountFallback = getAggregationCount(Payment.ProcessorType.FALLBACK, from, to);
        
        BigDecimal totalAmountDefault = getAggregationAmount(Payment.ProcessorType.DEFAULT, from, to);
        BigDecimal totalAmountFallback = getAggregationAmount(Payment.ProcessorType.FALLBACK, from, to);
        
        return new PaymentsSummaryResponse(
            formatAmount(totalAmountDefault),
            totalCountDefault,
            formatAmount(totalAmountFallback),
            totalCountFallback,
            new PaymentsSummaryResponse.Interval(from.toString(), to.toString())
        );
    }
    
    private void updateAggregation(Payment payment) {
        String dateKey = payment.processedAt().truncatedTo(ChronoUnit.DAYS).toString();
        String processorType = payment.processor().name().toLowerCase();
        
        String countKey = AGGREGATION_KEY_PREFIX + "count:" + processorType + ":" + dateKey;
        String amountKey = AGGREGATION_KEY_PREFIX + "amount:" + processorType + ":" + dateKey;
        
        // Increment count
        redisTemplate.opsForValue().increment(countKey);
        redisTemplate.expire(countKey, Duration.ofDays(30));
        
        // Add amount (store as cents to avoid floating point issues)
        long amountCents = payment.amount().multiply(BigDecimal.valueOf(100)).longValue();
        redisTemplate.opsForValue().increment(amountKey, amountCents);
        redisTemplate.expire(amountKey, Duration.ofDays(30));
    }
    
    private long getAggregationCount(Payment.ProcessorType processor, Instant from, Instant to) {
        long total = 0;
        Set<String> keys = getAggregationKeys("count", processor.name().toLowerCase(), from, to);
        
        for (String key : keys) {
            Object value = redisTemplate.opsForValue().get(key);
            if (value instanceof Number) {
                total += ((Number) value).longValue();
            }
        }
        
        return total;
    }
    
    private BigDecimal getAggregationAmount(Payment.ProcessorType processor, Instant from, Instant to) {
        long totalCents = 0;
        Set<String> keys = getAggregationKeys("amount", processor.name().toLowerCase(), from, to);
        
        for (String key : keys) {
            Object value = redisTemplate.opsForValue().get(key);
            if (value instanceof Number) {
                totalCents += ((Number) value).longValue();
            }
        }
        
        return BigDecimal.valueOf(totalCents).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }
    
    private Set<String> getAggregationKeys(String type, String processor, Instant from, Instant to) {
        String pattern = AGGREGATION_KEY_PREFIX + type + ":" + processor + ":*";
        return redisTemplate.keys(pattern);
    }
    
    private String formatAmount(BigDecimal amount) {
        return amount.setScale(2, RoundingMode.HALF_UP).toPlainString();
    }
}