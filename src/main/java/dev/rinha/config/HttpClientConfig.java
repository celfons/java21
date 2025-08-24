package dev.rinha.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.net.http.HttpClient;
import java.time.Duration;
import java.util.concurrent.Executors;

/**
 * HTTP client configuration for external payment processors.
 */
@Configuration
public class HttpClientConfig {
    
    @Value("${processor.connect-timeout:50ms}")
    private Duration connectTimeout;
    
    @Value("${processor.request-timeout:80ms}")
    private Duration requestTimeout;
    
    @Bean
    public HttpClient httpClient() {
        return HttpClient.newBuilder()
                .executor(Executors.newVirtualThreadPerTaskExecutor())
                .connectTimeout(connectTimeout)
                .build();
    }
}