package com.celfons.productcrud.kafka.circuitbreaker;

import com.celfons.productcrud.kafka.testutil.FakeClock;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for TopicFailureTracker.
 */
class TopicFailureTrackerTest {
    
    private TopicFailureTracker tracker;
    private FakeClock fakeClock;
    
    @BeforeEach
    void setUp() {
        fakeClock = new FakeClock();
        tracker = new TopicFailureTracker(fakeClock);
    }
    
    @Test
    void testRecordFailure_BelowThreshold_DoesNotTrip() {
        String topic = "test-topic";
        
        // Record 9 failures (below threshold of 10)
        for (int i = 0; i < 9; i++) {
            boolean shouldTrip = tracker.recordFailure(topic);
            assertFalse(shouldTrip, "Circuit should not trip at failure " + (i + 1));
        }
        
        assertEquals(9, tracker.getFailureCount(topic));
    }
    
    @Test
    void testRecordFailure_AtThreshold_Trips() {
        String topic = "test-topic";
        
        // Record 9 failures
        for (int i = 0; i < 9; i++) {
            tracker.recordFailure(topic);
        }
        
        // 10th failure should trip
        boolean shouldTrip = tracker.recordFailure(topic);
        assertTrue(shouldTrip, "Circuit should trip at 10th failure");
        assertEquals(10, tracker.getFailureCount(topic));
    }
    
    @Test
    void testRecordSuccess_ResetsFailureCount() {
        String topic = "test-topic";
        
        // Record some failures
        for (int i = 0; i < 5; i++) {
            tracker.recordFailure(topic);
        }
        
        assertEquals(5, tracker.getFailureCount(topic));
        
        // Record success - should reset
        tracker.recordSuccess(topic);
        
        assertEquals(0, tracker.getFailureCount(topic));
    }
    
    @Test
    void testTimeWindow_FailuresOutsideWindowAreRemoved() {
        String topic = "test-topic";
        
        // Record 5 failures at time 0
        for (int i = 0; i < 5; i++) {
            tracker.recordFailure(topic);
        }
        
        // Advance time by 61 seconds (outside the 60s window)
        fakeClock.advance(61);
        
        // Record a new failure - old ones should be removed
        tracker.recordFailure(topic);
        
        // Should only have 1 failure (the new one)
        assertEquals(1, tracker.getFailureCount(topic));
    }
    
    @Test
    void testTimeWindow_ConsecutiveFailuresWithinWindow() {
        String topic = "test-topic";
        
        // Record failures over time, all within 60s window
        for (int i = 0; i < 10; i++) {
            tracker.recordFailure(topic);
            fakeClock.advance(5); // Advance 5 seconds each time (total 45s)
        }
        
        // 11th failure should trip (10 from loop + 1 more = 11 total)
        boolean shouldTrip = tracker.recordFailure(topic);
        assertTrue(shouldTrip, "Should trip when 10+ failures within 60s window");
    }
    
    @Test
    void testMultipleTopics_IndependentTracking() {
        String topic1 = "topic-1";
        String topic2 = "topic-2";
        
        // Record failures for topic1
        for (int i = 0; i < 10; i++) {
            tracker.recordFailure(topic1);
        }
        
        // Record failures for topic2
        for (int i = 0; i < 5; i++) {
            tracker.recordFailure(topic2);
        }
        
        assertEquals(10, tracker.getFailureCount(topic1));
        assertEquals(5, tracker.getFailureCount(topic2));
        
        // Reset topic1 shouldn't affect topic2
        tracker.recordSuccess(topic1);
        
        assertEquals(0, tracker.getFailureCount(topic1));
        assertEquals(5, tracker.getFailureCount(topic2));
    }
    
    @Test
    void testReset_ClearsAllFailures() {
        tracker.recordFailure("topic-1");
        tracker.recordFailure("topic-2");
        tracker.recordFailure("topic-3");
        
        assertEquals(1, tracker.getFailureCount("topic-1"));
        assertEquals(1, tracker.getFailureCount("topic-2"));
        assertEquals(1, tracker.getFailureCount("topic-3"));
        
        tracker.reset();
        
        assertEquals(0, tracker.getFailureCount("topic-1"));
        assertEquals(0, tracker.getFailureCount("topic-2"));
        assertEquals(0, tracker.getFailureCount("topic-3"));
    }
    
    @Test
    void testRecordSuccess_NoFailures_DoesNothing() {
        String topic = "test-topic";
        
        // Record success without any prior failures
        tracker.recordSuccess(topic);
        
        // Should still be 0
        assertEquals(0, tracker.getFailureCount(topic));
    }
}
