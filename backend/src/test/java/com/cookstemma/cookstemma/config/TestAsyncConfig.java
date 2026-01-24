package com.cookstemma.cookstemma.config;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.core.task.SyncTaskExecutor;
import org.springframework.core.task.TaskExecutor;
import org.springframework.scheduling.annotation.AsyncConfigurer;

import java.util.concurrent.Executor;

/**
 * Test configuration that uses synchronous execution for @Async methods.
 * This prevents TaskRejectedException in tests when the async executor
 * is shutting down or has limited capacity.
 */
@TestConfiguration
public class TestAsyncConfig implements AsyncConfigurer {

    @Override
    public Executor getAsyncExecutor() {
        // Use synchronous executor in tests to avoid TaskRejectedException
        return new SyncTaskExecutor();
    }

    @Bean
    @Primary
    public TaskExecutor taskExecutor() {
        return new SyncTaskExecutor();
    }
}
