package com.celfons.productcrud.service;

import com.celfons.productcrud.model.Product;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

/**
 * Service interface for Product operations.
 * Defines the contract for product business logic.
 * Follows Interface Segregation Principle from SOLID.
 */
public interface ProductService {
    
    /**
     * Create a new product.
     */
    Product createProduct(Product product);
    
    /**
     * Get all products.
     */
    List<Product> getAllProducts();
    
    /**
     * Get product by ID.
     */
    Optional<Product> getProductById(String id);
    
    /**
     * Update an existing product.
     */
    Product updateProduct(String id, Product product);
    
    /**
     * Delete a product by ID.
     */
    void deleteProduct(String id);
    
    /**
     * Search products by name.
     */
    List<Product> searchProductsByName(String name);
    
    /**
     * Find products by price range.
     */
    List<Product> findProductsByPriceRange(BigDecimal minPrice, BigDecimal maxPrice);
}