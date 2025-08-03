package com.celfons.crud.exception;

/**
 * Exception thrown when there's a business logic conflict.
 */
public class BusinessException extends RuntimeException {

    public BusinessException(String message) {
        super(message);
    }

    public BusinessException(String message, Throwable cause) {
        super(message, cause);
    }

    public static BusinessException emailAlreadyExists(String email) {
        return new BusinessException("Email already exists: " + email);
    }
}