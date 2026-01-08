package com.pairingplanet.pairing_planet.scheduler;

import com.pairingplanet.pairing_planet.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class AccountCleanupScheduler {

    private final UserService userService;

    /**
     * 매일 자정에 실행 - 유예 기간이 지난 삭제된 계정 영구 삭제
     */
    @Scheduled(cron = "0 0 0 * * *")
    public void purgeExpiredDeletedAccounts() {
        log.info("Starting scheduled account cleanup job");
        userService.purgeExpiredDeletedAccounts();
        log.info("Completed scheduled account cleanup job");
    }
}
