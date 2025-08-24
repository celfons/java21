package dev.rinha.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Simple circuit breaker implementation for external processors.
 */
@Component
public class CircuitBreaker {
    
    public enum State {
        CLOSED, OPEN, HALF_OPEN
    }
    
    @Value("${circuit.breaker.failure-threshold:3}")
    private int failureThreshold;
    
    @Value("${circuit.breaker.open-duration:750ms}")
    private Duration openDuration;
    
    @Value("${circuit.breaker.half-open-requests:2}")
    private int halfOpenRequests;
    
    private final AtomicReference<State> state = new AtomicReference<>(State.CLOSED);
    private final AtomicInteger consecutiveFailures = new AtomicInteger(0);
    private final AtomicInteger halfOpenAttempts = new AtomicInteger(0);
    private volatile Instant lastFailureTime;
    
    public boolean canExecute() {
        State currentState = state.get();
        
        switch (currentState) {
            case CLOSED:
                return true;
            case OPEN:
                if (shouldTransitionToHalfOpen()) {
                    state.compareAndSet(State.OPEN, State.HALF_OPEN);
                    halfOpenAttempts.set(0);
                    return true;
                }
                return false;
            case HALF_OPEN:
                return halfOpenAttempts.get() < halfOpenRequests;
            default:
                return false;
        }
    }
    
    public void recordSuccess() {
        consecutiveFailures.set(0);
        if (state.get() == State.HALF_OPEN) {
            state.set(State.CLOSED);
            halfOpenAttempts.set(0);
        }
    }
    
    public void recordFailure() {
        lastFailureTime = Instant.now();
        int failures = consecutiveFailures.incrementAndGet();
        
        if (state.get() == State.HALF_OPEN) {
            state.set(State.OPEN);
            halfOpenAttempts.set(0);
        } else if (failures >= failureThreshold) {
            state.set(State.OPEN);
        }
        
        if (state.get() == State.HALF_OPEN) {
            halfOpenAttempts.incrementAndGet();
        }
    }
    
    private boolean shouldTransitionToHalfOpen() {
        return lastFailureTime != null && 
               Instant.now().isAfter(lastFailureTime.plus(openDuration));
    }
    
    public State getState() {
        return state.get();
    }
}