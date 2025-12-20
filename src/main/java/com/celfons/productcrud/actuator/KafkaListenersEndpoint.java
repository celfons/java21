package com.celfons.productcrud.actuator;

import org.springframework.boot.actuate.endpoint.annotation.Endpoint;
import org.springframework.boot.actuate.endpoint.annotation.ReadOperation;
import org.springframework.boot.actuate.endpoint.annotation.Selector;
import org.springframework.boot.actuate.endpoint.annotation.WriteOperation;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.listener.MessageListenerContainer;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Custom Actuator endpoint for managing Kafka listeners.
 * Provides operations to list, enable, and disable all Kafka listener containers.
 */
@Component
@Endpoint(id = "kafka-listeners")
public class KafkaListenersEndpoint {

    private final KafkaListenerEndpointRegistry registry;

    public KafkaListenersEndpoint(KafkaListenerEndpointRegistry registry) {
        this.registry = registry;
    }

    /**
     * GET /actuator/kafka-listeners
     * Returns a list of all registered Kafka listener containers with their status.
     */
    @ReadOperation
    public Map<String, Object> listListeners() {
        Map<String, Object> response = new HashMap<>();
        List<Map<String, Object>> listeners = new ArrayList<>();
        
        int runningCount = 0;
        int stoppedCount = 0;

        for (MessageListenerContainer container : registry.getAllListenerContainers()) {
            Map<String, Object> listenerInfo = new HashMap<>();
            String listenerId = container.getListenerId();
            boolean isRunning = container.isRunning();
            
            listenerInfo.put("id", listenerId != null ? listenerId : "unknown");
            listenerInfo.put("running", isRunning);
            listenerInfo.put("containerClass", container.getClass().getSimpleName());
            
            listeners.add(listenerInfo);
            
            if (isRunning) {
                runningCount++;
            } else {
                stoppedCount++;
            }
        }
        
        response.put("listeners", listeners);
        response.put("totalCount", listeners.size());
        response.put("runningCount", runningCount);
        response.put("stoppedCount", stoppedCount);
        
        return response;
    }

    /**
     * POST /actuator/kafka-listeners/enable or /actuator/kafka-listeners/disable
     * Manages Kafka listener containers based on the action selector.
     */
    @WriteOperation
    public Map<String, Object> manageListeners(@Selector String action) {
        if ("enable".equals(action)) {
            return enable();
        } else if ("disable".equals(action)) {
            return disable();
        } else {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Invalid action. Use 'enable' or 'disable'");
            return error;
        }
    }

    private Map<String, Object> enable() {
        List<String> enabledListeners = new ArrayList<>();
        
        for (MessageListenerContainer container : registry.getAllListenerContainers()) {
            if (!container.isRunning()) {
                container.start();
                String listenerId = container.getListenerId();
                enabledListeners.add(listenerId != null ? listenerId : "unknown");
            }
        }
        
        Map<String, Object> response = listListeners();
        response.put("action", "enable");
        response.put("enabledListeners", enabledListeners);
        response.put("message", "All listener containers have been started");
        
        return response;
    }

    private Map<String, Object> disable() {
        List<String> disabledListeners = new ArrayList<>();
        
        for (MessageListenerContainer container : registry.getAllListenerContainers()) {
            if (container.isRunning()) {
                container.stop();
                String listenerId = container.getListenerId();
                disabledListeners.add(listenerId != null ? listenerId : "unknown");
            }
        }
        
        Map<String, Object> response = listListeners();
        response.put("action", "disable");
        response.put("disabledListeners", disabledListeners);
        response.put("message", "All listener containers have been stopped");
        
        return response;
    }
}
