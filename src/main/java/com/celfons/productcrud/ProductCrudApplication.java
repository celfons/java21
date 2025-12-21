package com.celfons.productcrud;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Main application class for Product CRUD API.
 * Uses Java 21 virtual threads and MongoDB Atlas.
 */
@SpringBootApplication
@EnableScheduling
public class ProductCrudApplication {

    public static void main(String[] args) {
        SpringApplication.run(ProductCrudApplication.class, args);
    }
}