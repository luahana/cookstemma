package com.cookstemma.cookstemma.repository.user;

import com.cookstemma.cookstemma.domain.entity.bot.BotPersona;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.AccountStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {
    // API 조회용 (UUID)
    Optional<User> findByPublicId(UUID publicId);

    // 로그인/가입용
    Optional<User> findByUsername(String username);
    Optional<User> findByUsernameIgnoreCase(String username);
    Optional<User> findByEmail(String email);
    boolean existsByUsername(String username);
    boolean existsByUsernameIgnoreCase(String username);

    // Bot users
    Optional<User> findByPersona(BotPersona persona);

    // 계정 삭제 스케줄러용 - 유예 기간이 지난 삭제된 계정 조회
    List<User> findByStatusAndDeleteScheduledAtBefore(AccountStatus status, Instant cutoffTime);

    // Sitemap용 - 활성 사용자의 publicId 목록 조회
    @Query("SELECT u.publicId FROM User u WHERE u.status = :status ORDER BY u.createdAt DESC")
    List<UUID> findPublicIdsByStatusOrderByCreatedAtDesc(@Param("status") AccountStatus status, Pageable pageable);
}