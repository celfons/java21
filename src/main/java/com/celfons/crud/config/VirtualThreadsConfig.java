package com.celfons.crud.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;

import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

/**
 * Configuration class for virtual threads and async processing.
 * Demonstrates Java 21 virtual threads integration with Spring Boot.
 */
@Configuration
@EnableAsync
public class VirtualThreadsConfig {

    private static final Logger logger = LoggerFactory.getLogger(VirtualThreadsConfig.class);

    /**
     * Bean for virtual thread executor.
     * This executor uses Java 21 virtual threads for lightweight concurrent processing.
     */
    @Bean(name = "virtualThreadExecutor")
    public Executor virtualThreadExecutor() {
        logger.info("Creating virtual thread executor");
        
        return Executors.newVirtualThreadPerTaskExecutor();
    }

    /**
     * Custom thread factory for demonstration purposes.
     * Shows how to create named virtual threads.
     */
    @Bean(name = "namedVirtualThreadExecutor")
    public Executor namedVirtualThreadExecutor() {
        logger.info("Creating named virtual thread executor");
        
        return Executors.newThreadPerTaskExecutor(Thread.ofVirtual()
                .name("crud-virtual-", 0)
                .factory());
    }
}