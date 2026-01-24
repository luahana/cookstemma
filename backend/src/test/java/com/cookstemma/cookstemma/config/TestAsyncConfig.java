package com.cookstemma.cookstemma.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.core.task.SyncTaskExecutor;
import org.springframework.scheduling.annotation.EnableAsync;

import java.util.concurrent.Executor;

/**
 * Test configuration that uses synchronous execution for @Async methods.
 * This prevents TaskRejectedException in tests when the async executor
 * is shutting down or has limited capacity.
 */
@Configuration
@EnableAsync
@Profile("test")
public class TestAsyncConfig {

    @Bean(name = "imageProcessingExecutor")
    public Executor imageProcessingExecutor() {
        return new SyncTaskExecutor();
    }
}
