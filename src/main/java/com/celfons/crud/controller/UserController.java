package com.celfons.crud.controller;

import com.celfons.crud.dto.UserCreateDTO;
import com.celfons.crud.dto.UserResponseDTO;
import com.celfons.crud.dto.UserUpdateDTO;
import com.celfons.crud.service.UserService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

/**
 * REST Controller for User CRUD operations.
 * Demonstrates Spring Boot REST API with validation and virtual threads.
 */
@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    private static final Logger logger = LoggerFactory.getLogger(UserController.class);

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    /**
     * Create a new user.
     * POST /api/users
     */
    @PostMapping
    public ResponseEntity<UserResponseDTO> createUser(@Valid @RequestBody UserCreateDTO createDTO) {
        logger.info("Creating user: {}", createDTO.getEmail());
        UserResponseDTO user = userService.createUser(createDTO);
        return new ResponseEntity<>(user, HttpStatus.CREATED);
    }

    /**
     * Get user by ID.
     * GET /api/users/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<UserResponseDTO> getUserById(@PathVariable Long id) {
        logger.debug("Getting user by id: {}", id);
        UserResponseDTO user = userService.getUserById(id);
        return ResponseEntity.ok(user);
    }

    /**
     * Get all users with pagination and sorting.
     * GET /api/users?page=0&size=10&sort=name,asc
     */
    @GetMapping
    public ResponseEntity<Page<UserResponseDTO>> getAllUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDir) {
        
        logger.debug("Getting users - page: {}, size: {}, sortBy: {}, sortDir: {}", page, size, sortBy, sortDir);
        
        Sort sort = Sort.by(Sort.Direction.fromString(sortDir), sortBy);
        Pageable pageable = PageRequest.of(page, size, sort);
        
        Page<UserResponseDTO> users = userService.getAllUsers(pageable);
        return ResponseEntity.ok(users);
    }

    /**
     * Update user by ID.
     * PUT /api/users/{id}
     */
    @PutMapping("/{id}")
    public ResponseEntity<UserResponseDTO> updateUser(@PathVariable Long id, 
                                                     @Valid @RequestBody UserUpdateDTO updateDTO) {
        logger.info("Updating user: {}", id);
        UserResponseDTO user = userService.updateUser(id, updateDTO);
        return ResponseEntity.ok(user);
    }

    /**
     * Delete user by ID.
     * DELETE /api/users/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        logger.info("Deleting user: {}", id);
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Search users asynchronously - demonstrates virtual threads.
     * GET /api/users/search?term=john
     */
    @GetMapping("/search")
    public CompletableFuture<ResponseEntity<List<UserResponseDTO>>> searchUsers(
            @RequestParam String term) {
        logger.info("Searching users with term: {}", term);
        
        return userService.searchUsersAsync(term)
                .thenApply(users -> {
                    logger.debug("Search completed, found {} users", users.size());
                    return ResponseEntity.ok(users);
                });
    }

    /**
     * Get statistics - demonstrates virtual threads usage.
     * GET /api/users/stats
     */
    @GetMapping("/stats")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> getUserStats() {
        logger.info("Getting user statistics");
        
        return userService.getActiveUsersCountAsync()
                .thenApply(activeCount -> {
                    Map<String, Object> stats = Map.of(
                            "activeUsers", activeCount,
                            "threadInfo", Map.of(
                                    "currentThread", Thread.currentThread().getName(),
                                    "isVirtual", Thread.currentThread().isVirtual()
                            )
                    );
                    logger.debug("Statistics retrieved: {}", stats);
                    return ResponseEntity.ok(stats);
                });
    }

    /**
     * Bulk create users - demonstrates async processing.
     * POST /api/users/bulk
     */
    @PostMapping("/bulk")
    public CompletableFuture<ResponseEntity<List<UserResponseDTO>>> createUsersInBulk(
            @Valid @RequestBody List<UserCreateDTO> createDTOs) {
        logger.info("Creating {} users in bulk", createDTOs.size());
        
        return userService.createUsersInBulk(createDTOs)
                .thenApply(users -> {
                    logger.info("Bulk creation completed, {} users created successfully", users.size());
                    return ResponseEntity.status(HttpStatus.CREATED).body(users);
                });
    }

    /**
     * Health check endpoint - shows virtual thread information.
     * GET /api/users/health
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> health = Map.of(
                "status", "UP",
                "thread", Map.of(
                        "name", Thread.currentThread().getName(),
                        "isVirtual", Thread.currentThread().isVirtual(),
                        "threadClass", Thread.currentThread().getClass().getSimpleName()
                ),
                "timestamp", java.time.LocalDateTime.now()
        );
        return ResponseEntity.ok(health);
    }
}