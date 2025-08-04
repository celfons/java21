package com.celfons.productcrud.service;

import com.celfons.productcrud.model.Product;
import com.celfons.productcrud.repository.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Unit tests for ProductServiceImpl.
 * Tests business logic in isolation using mocks.
 */
class ProductServiceImplTest {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductServiceImpl productService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void createProduct_ValidProduct_ReturnsCreatedProduct() {
        // Arrange
        Product product = new Product("Test Product", "Test Description", new BigDecimal("99.99"));
        Product savedProduct = new Product("Test Product", "Test Description", new BigDecimal("99.99"));
        savedProduct.setId("1");

        when(productRepository.save(any(Product.class))).thenReturn(savedProduct);

        // Act
        Product result = productService.createProduct(product);

        // Assert
        assertNotNull(result);
        assertEquals("1", result.getId());
        assertEquals("Test Product", result.getName());
        verify(productRepository, times(1)).save(any(Product.class));
    }

    @Test
    void createProduct_NullProduct_ThrowsException() {
        // Act & Assert
        assertThrows(IllegalArgumentException.class, () -> {
            productService.createProduct(null);
        });
    }

    @Test
    void getProductById_ValidId_ReturnsProduct() {
        // Arrange
        String productId = "1";
        Product product = new Product("Test Product", "Test Description", new BigDecimal("99.99"));
        product.setId(productId);

        when(productRepository.findById(productId)).thenReturn(Optional.of(product));

        // Act
        Optional<Product> result = productService.getProductById(productId);

        // Assert
        assertTrue(result.isPresent());
        assertEquals(productId, result.get().getId());
        verify(productRepository, times(1)).findById(productId);
    }

    @Test
    void getProductById_InvalidId_ThrowsException() {
        // Act & Assert
        assertThrows(IllegalArgumentException.class, () -> {
            productService.getProductById(null);
        });

        assertThrows(IllegalArgumentException.class, () -> {
            productService.getProductById("");
        });
    }

    @Test
    void deleteProduct_ExistingProduct_DeletesSuccessfully() {
        // Arrange
        String productId = "1";
        when(productRepository.existsById(productId)).thenReturn(true);

        // Act
        productService.deleteProduct(productId);

        // Assert
        verify(productRepository, times(1)).existsById(productId);
        verify(productRepository, times(1)).deleteById(productId);
    }

    @Test
    void deleteProduct_NonExistingProduct_ThrowsException() {
        // Arrange
        String productId = "999";
        when(productRepository.existsById(productId)).thenReturn(false);

        // Act & Assert
        assertThrows(IllegalArgumentException.class, () -> {
            productService.deleteProduct(productId);
        });
    }
}