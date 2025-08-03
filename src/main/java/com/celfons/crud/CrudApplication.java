package com.celfons.crud;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main Spring Boot application class for the CRUD API.
 * 
 * This application demonstrates:
 * - Java 21 virtual threads integration
 * - Modern CRUD operations with REST API
 * - H2 database for development and testing
 * - GraalVM native compilation support
 */
@SpringBootApplication
public class CrudApplication {

    public static void main(String[] args) {
        SpringApplication.run(CrudApplication.class, args);
    }
}