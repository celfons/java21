package com.celfons.crud.service;

import com.celfons.crud.dto.UserCreateDTO;
import com.celfons.crud.dto.UserResponseDTO;
import com.celfons.crud.dto.UserUpdateDTO;
import com.celfons.crud.entity.User;
import com.celfons.crud.exception.BusinessException;
import com.celfons.crud.exception.ResourceNotFoundException;
import com.celfons.crud.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;
import java.util.stream.Collectors;

/**
 * Service class for User operations.
 * Demonstrates virtual threads usage and asynchronous processing.
 */
@Service
@Transactional
public class UserService {

    private static final Logger logger = LoggerFactory.getLogger(UserService.class);

    private final UserRepository userRepository;
    private final Executor virtualThreadExecutor;

    public UserService(UserRepository userRepository, Executor virtualThreadExecutor) {
        this.userRepository = userRepository;
        this.virtualThreadExecutor = virtualThreadExecutor;
    }

    /**
     * Create a new user.
     */
    public UserResponseDTO createUser(UserCreateDTO createDTO) {
        logger.debug("Creating user with email: {}", createDTO.getEmail());

        // Check if email already exists
        if (userRepository.existsByEmailIgnoreCase(createDTO.getEmail())) {
            throw BusinessException.emailAlreadyExists(createDTO.getEmail());
        }

        User user = new User(createDTO.getName(), createDTO.getEmail(), createDTO.getPhone());
        User savedUser = userRepository.save(user);

        logger.info("User created successfully with id: {}", savedUser.getId());
        return mapToResponseDTO(savedUser);
    }

    /**
     * Get user by ID.
     */
    @Transactional(readOnly = true)
    public UserResponseDTO getUserById(Long id) {
        logger.debug("Retrieving user with id: {}", id);
        
        User user = userRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.forUser(id));
        
        return mapToResponseDTO(user);
    }

    /**
     * Get all users with pagination.
     */
    @Transactional(readOnly = true)
    public Page<UserResponseDTO> getAllUsers(Pageable pageable) {
        logger.debug("Retrieving users with pagination: {}", pageable);
        
        Page<User> userPage = userRepository.findAll(pageable);
        List<UserResponseDTO> userDTOs = userPage.getContent().stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
        
        return new PageImpl<>(userDTOs, pageable, userPage.getTotalElements());
    }

    /**
     * Update user - demonstrates virtual threads usage.
     */
    public UserResponseDTO updateUser(Long id, UserUpdateDTO updateDTO) {
        logger.debug("Updating user with id: {}", id);

        User user = userRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.forUser(id));

        // Check email uniqueness if email is being updated
        if (updateDTO.getEmail() != null && !updateDTO.getEmail().equalsIgnoreCase(user.getEmail())) {
            if (userRepository.existsByEmailIgnoreCase(updateDTO.getEmail())) {
                throw BusinessException.emailAlreadyExists(updateDTO.getEmail());
            }
        }

        // Update fields
        if (updateDTO.getName() != null) {
            user.setName(updateDTO.getName());
        }
        if (updateDTO.getEmail() != null) {
            user.setEmail(updateDTO.getEmail());
        }
        if (updateDTO.getPhone() != null) {
            user.setPhone(updateDTO.getPhone());
        }
        if (updateDTO.getActive() != null) {
            user.setActive(updateDTO.getActive());
        }

        User savedUser = userRepository.save(user);
        logger.info("User updated successfully with id: {}", savedUser.getId());
        
        return mapToResponseDTO(savedUser);
    }

    /**
     * Delete user by ID.
     */
    public void deleteUser(Long id) {
        logger.debug("Deleting user with id: {}", id);
        
        if (!userRepository.existsById(id)) {
            throw ResourceNotFoundException.forUser(id);
        }
        
        userRepository.deleteById(id);
        logger.info("User deleted successfully with id: {}", id);
    }

    /**
     * Search users by name or email - demonstrates async processing with virtual threads.
     */
    @Async("virtualThreadExecutor")
    public CompletableFuture<List<UserResponseDTO>> searchUsersAsync(String searchTerm) {
        logger.debug("Async search for users with term: {}", searchTerm);
        
        return CompletableFuture.supplyAsync(() -> {
            // Simulate some processing time
            try {
                Thread.sleep(100);
                logger.debug("Processing search on virtual thread: {}", Thread.currentThread().getName());
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Search interrupted", e);
            }
            
            List<User> users = userRepository.findByNameOrEmailContaining(searchTerm);
            return users.stream()
                    .map(this::mapToResponseDTO)
                    .collect(Collectors.toList());
        }, virtualThreadExecutor);
    }

    /**
     * Get active users count - demonstrates virtual threads.
     */
    @Async("virtualThreadExecutor")
    public CompletableFuture<Long> getActiveUsersCountAsync() {
        logger.debug("Getting active users count asynchronously");
        
        return CompletableFuture.supplyAsync(() -> {
            logger.debug("Counting active users on virtual thread: {}", Thread.currentThread().getName());
            return userRepository.countActiveUsers();
        }, virtualThreadExecutor);
    }

    /**
     * Bulk operations example with virtual threads.
     */
    @Async("virtualThreadExecutor")
    public CompletableFuture<List<UserResponseDTO>> createUsersInBulk(List<UserCreateDTO> createDTOs) {
        logger.debug("Creating {} users in bulk", createDTOs.size());
        
        return CompletableFuture.supplyAsync(() -> {
            logger.debug("Processing bulk creation on virtual thread: {}", Thread.currentThread().getName());
            
            return createDTOs.stream()
                    .map(dto -> {
                        try {
                            return createUser(dto);
                        } catch (BusinessException e) {
                            logger.warn("Failed to create user with email {}: {}", dto.getEmail(), e.getMessage());
                            return null;
                        }
                    })
                    .filter(dto -> dto != null)
                    .collect(Collectors.toList());
        }, virtualThreadExecutor);
    }

    // Helper method to map entity to DTO
    private UserResponseDTO mapToResponseDTO(User user) {
        return new UserResponseDTO(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getPhone(),
                user.getActive(),
                user.getCreatedAt(),
                user.getUpdatedAt()
        );
    }
}