package com.celfons.productcrud.repository;

import com.celfons.productcrud.model.Product;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

/**
 * Repository interface for Product entity.
 * Follows the Repository pattern and SOLID principles.
 * Extends MongoRepository for basic CRUD operations.
 */
@Repository
public interface ProductRepository extends MongoRepository<Product, String> {
    
    /**
     * Find products by name containing the given text (case-insensitive).
     */
    List<Product> findByNameContainingIgnoreCase(String name);
    
    /**
     * Find products by price range.
     */
    List<Product> findByPriceBetween(BigDecimal minPrice, BigDecimal maxPrice);
    
    /**
     * Find products by exact name (case-insensitive).
     */
    List<Product> findByNameIgnoreCase(String name);
}