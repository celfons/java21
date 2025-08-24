package dev.rinha.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.rinha.dto.PaymentRequest;
import dev.rinha.service.PaymentService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Unit tests for PaymentController.
 */
@WebMvcTest(PaymentController.class)
class PaymentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private PaymentService paymentService;

    @Test
    void processPayment_ValidRequest_ShouldReturn200() throws Exception {
        // Arrange
        PaymentRequest request = new PaymentRequest(
            UUID.randomUUID(),
            new BigDecimal("100.50")
        );
        
        doNothing().when(paymentService).processPayment(any(PaymentRequest.class));

        // Act & Assert
        mockMvc.perform(post("/payments")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());
    }

    @Test
    void processPayment_InvalidRequest_ShouldReturn400() throws Exception {
        // Arrange - Invalid request with negative amount
        PaymentRequest request = new PaymentRequest(
            UUID.randomUUID(),
            new BigDecimal("-100.50")
        );

        // Act & Assert
        mockMvc.perform(post("/payments")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void processPayment_MissingCorrelationId_ShouldReturn400() throws Exception {
        // Arrange - Request with null correlationId
        String invalidJson = "{\"correlationId\": null, \"amount\": 100.50}";

        // Act & Assert
        mockMvc.perform(post("/payments")
                .contentType(MediaType.APPLICATION_JSON)
                .content(invalidJson))
                .andExpect(status().isBadRequest());
    }
}