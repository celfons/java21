package com.celfons.productcrud.kafka.testutil;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;

/**
 * Fake clock implementation for testing time-based logic.
 * Allows manual control of time progression in tests.
 */
public class FakeClock extends Clock {
    private Instant currentTime = Instant.parse("2024-01-01T00:00:00Z");
    
    /**
     * Advances the clock by the specified number of seconds.
     * 
     * @param seconds the number of seconds to advance
     */
    public void advance(long seconds) {
        currentTime = currentTime.plusSeconds(seconds);
    }
    
    /**
     * Sets the clock to a specific instant.
     * 
     * @param instant the instant to set
     */
    public void setInstant(Instant instant) {
        currentTime = instant;
    }
    
    @Override
    public Instant instant() {
        return currentTime;
    }
    
    @Override
    public ZoneId getZone() {
        return ZoneId.of("UTC");
    }
    
    @Override
    public Clock withZone(ZoneId zone) {
        return this;
    }
}
