package com.cookstemma.cookstemma.domain.entity.history;

import com.cookstemma.cookstemma.domain.entity.user.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "search_history")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class SearchHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false)
    private User user;

    @Column(nullable = false, length = 500)
    private String query;

    @Column(name = "searched_at", nullable = false)
    private Instant searchedAt;

    @PrePersist
    protected void onCreate() {
        searchedAt = Instant.now();
    }
}
