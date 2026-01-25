package com.cookstemma.cookstemma.domain.entity.comment;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CommentLikeId implements Serializable {
    private Long userId;
    private Long commentId;
}
