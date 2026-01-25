package com.cookstemma.cookstemma.scheduler;

import com.cookstemma.cookstemma.service.ImageService;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ImageCleanupScheduler {

    private final ImageService imageService;

    // 1시간마다 실행 (원하는 주기로 변경 가능)
    @Scheduled(cron = "0 0 * * * *")
    public void cleanupUnusedImages() {
        imageService.deleteUnusedImages();
    }
}