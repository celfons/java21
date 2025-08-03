package com.celfons.crud.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;
import java.time.Duration;
import java.time.LocalDateTime;

/**
 * Controller demonstrating virtual threads capabilities.
 * Shows different patterns of virtual thread usage.
 */
@RestController
@RequestMapping("/api/virtual-threads")
public class VirtualThreadsDemoController {

    private final Executor virtualThreadExecutor;

    public VirtualThreadsDemoController(Executor virtualThreadExecutor) {
        this.virtualThreadExecutor = virtualThreadExecutor;
    }

    /**
     * Basic virtual thread information.
     */
    @GetMapping("/info")
    public Map<String, Object> getThreadInfo() {
        Thread currentThread = Thread.currentThread();
        return Map.of(
                "threadName", currentThread.getName(),
                "isVirtual", currentThread.isVirtual(),
                "threadClass", currentThread.getClass().getSimpleName(),
                "threadId", currentThread.threadId(),
                "timestamp", LocalDateTime.now()
        );
    }

    /**
     * Simulate CPU-intensive work on virtual thread.
     */
    @GetMapping("/cpu-work")
    public CompletableFuture<Map<String, Object>> simulateCpuWork() {
        return CompletableFuture.supplyAsync(() -> {
            LocalDateTime start = LocalDateTime.now();
            
            // Simulate some CPU work
            long sum = 0;
            for (int i = 0; i < 1_000_000; i++) {
                sum += i;
            }
            
            LocalDateTime end = LocalDateTime.now();
            Duration duration = Duration.between(start, end);
            
            return Map.of(
                    "result", sum,
                    "duration", duration.toMillis() + " ms",
                    "thread", Map.of(
                            "name", Thread.currentThread().getName(),
                            "isVirtual", Thread.currentThread().isVirtual()
                    ),
                    "timestamp", end
            );
        }, virtualThreadExecutor);
    }

    /**
     * Simulate I/O blocking work on virtual thread.
     */
    @GetMapping("/io-work")
    public CompletableFuture<Map<String, Object>> simulateIoWork() {
        return CompletableFuture.supplyAsync(() -> {
            LocalDateTime start = LocalDateTime.now();
            
            try {
                // Simulate I/O blocking operation
                Thread.sleep(100);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Task interrupted", e);
            }
            
            LocalDateTime end = LocalDateTime.now();
            Duration duration = Duration.between(start, end);
            
            return Map.of(
                    "message", "I/O work completed",
                    "duration", duration.toMillis() + " ms",
                    "thread", Map.of(
                            "name", Thread.currentThread().getName(),
                            "isVirtual", Thread.currentThread().isVirtual()
                    ),
                    "timestamp", end
            );
        }, virtualThreadExecutor);
    }

    /**
     * Demonstrate multiple concurrent virtual threads.
     */
    @GetMapping("/concurrent-work")
    public CompletableFuture<Map<String, Object>> concurrentWork() {
        LocalDateTime start = LocalDateTime.now();
        
        // Start multiple virtual threads
        CompletableFuture<String> task1 = CompletableFuture.supplyAsync(() -> {
            try {
                Thread.sleep(50);
                return "Task 1 completed on " + Thread.currentThread().getName();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return "Task 1 interrupted";
            }
        }, virtualThreadExecutor);
        
        CompletableFuture<String> task2 = CompletableFuture.supplyAsync(() -> {
            try {
                Thread.sleep(75);
                return "Task 2 completed on " + Thread.currentThread().getName();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return "Task 2 interrupted";
            }
        }, virtualThreadExecutor);
        
        CompletableFuture<String> task3 = CompletableFuture.supplyAsync(() -> {
            try {
                Thread.sleep(25);
                return "Task 3 completed on " + Thread.currentThread().getName();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return "Task 3 interrupted";
            }
        }, virtualThreadExecutor);
        
        // Combine all tasks
        return CompletableFuture.allOf(task1, task2, task3)
                .thenApplyAsync(ignored -> {
                    LocalDateTime end = LocalDateTime.now();
                    Duration duration = Duration.between(start, end);
                    
                    return Map.of(
                            "results", Map.of(
                                    "task1", task1.join(),
                                    "task2", task2.join(),
                                    "task3", task3.join()
                            ),
                            "totalDuration", duration.toMillis() + " ms",
                            "coordinatorThread", Map.of(
                                    "name", Thread.currentThread().getName(),
                                    "isVirtual", Thread.currentThread().isVirtual()
                            ),
                            "timestamp", end
                    );
                }, virtualThreadExecutor);
    }
}