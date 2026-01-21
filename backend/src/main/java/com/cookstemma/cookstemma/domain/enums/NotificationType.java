package com.cookstemma.cookstemma.domain.enums;

public enum NotificationType {
    RECIPE_COOKED,    // Someone cooked your recipe (created log post)
    RECIPE_VARIATION, // Someone created a variation of your recipe
    NEW_FOLLOWER,     // Someone started following you
    COMMENT_ON_LOG,   // Someone commented on your cooking log
    COMMENT_REPLY     // Someone replied to your comment
}
