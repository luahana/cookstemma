package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.util.HtmlUtils;

import java.util.UUID;

/**
 * Service for generating shareable content with Open Graph meta tags.
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ShareService {

    private final RecipeRepository recipeRepository;
    private final UserRepository userRepository;

    @Value("${app.base-url:https://cookstemma.com}")
    private String appBaseUrl;

    @Value("${app.api-url:https://api.cookstemma.com}")
    private String apiBaseUrl;

    @Value("${file.upload.url-prefix}")
    private String imageUrlPrefix;

    private static final String DEFAULT_IMAGE = "https://cookstemma.com/images/og-default.png";
    private static final int MAX_TITLE_LENGTH = 60;
    private static final int MAX_DESCRIPTION_LENGTH = 160;

    /**
     * Generate HTML page with Open Graph meta tags for a recipe.
     * This is what social media crawlers fetch to generate link previews.
     */
    public String generateRecipeShareHtml(UUID recipePublicId) {
        Recipe recipe = recipeRepository.findByPublicId(recipePublicId)
                .orElse(null);

        if (recipe == null) {
            return generateNotFoundHtml();
        }

        String title = truncate(recipe.getTitle(), MAX_TITLE_LENGTH);
        String description = truncate(
                recipe.getDescription() != null ? recipe.getDescription() : "맛있는 레시피를 확인해보세요!",
                MAX_DESCRIPTION_LENGTH
        );
        String imageUrl = getImageUrl(recipe);
        String shareUrl = apiBaseUrl + "/share/recipe/" + recipePublicId;
        String deepLink = "cookstemma://recipe/" + recipePublicId;
        String userName = getCreatorName(recipe);

        // Escape HTML entities for safety
        title = HtmlUtils.htmlEscape(title);
        description = HtmlUtils.htmlEscape(description);
        userName = HtmlUtils.htmlEscape(userName);

        return """
                <!DOCTYPE html>
                <html lang="ko">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>%s - Cookstemma</title>

                    <!-- Open Graph / Facebook -->
                    <meta property="og:type" content="article">
                    <meta property="og:url" content="%s">
                    <meta property="og:title" content="%s">
                    <meta property="og:description" content="%s">
                    <meta property="og:image" content="%s">
                    <meta property="og:site_name" content="Cookstemma">
                    <meta property="og:locale" content="ko_KR">

                    <!-- Twitter -->
                    <meta name="twitter:card" content="summary_large_image">
                    <meta name="twitter:url" content="%s">
                    <meta name="twitter:title" content="%s">
                    <meta name="twitter:description" content="%s">
                    <meta name="twitter:image" content="%s">

                    <!-- KakaoTalk -->
                    <meta property="og:image:width" content="1200">
                    <meta property="og:image:height" content="630">

                    <!-- App Deep Link -->
                    <meta property="al:android:url" content="%s">
                    <meta property="al:android:package" content="com.cookstemma.app">
                    <meta property="al:android:app_name" content="Cookstemma">
                    <meta property="al:ios:url" content="%s">
                    <meta property="al:ios:app_store_id" content="YOUR_APP_STORE_ID">
                    <meta property="al:ios:app_name" content="Cookstemma">

                    <style>
                        body {
                            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                            display: flex;
                            flex-direction: column;
                            align-items: center;
                            justify-content: center;
                            min-height: 100vh;
                            margin: 0;
                            padding: 20px;
                            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
                            color: white;
                            text-align: center;
                        }
                        .container {
                            max-width: 400px;
                            background: rgba(255,255,255,0.1);
                            backdrop-filter: blur(10px);
                            border-radius: 20px;
                            padding: 30px;
                        }
                        img {
                            width: 100%%;
                            max-width: 300px;
                            border-radius: 12px;
                            margin-bottom: 20px;
                        }
                        h1 {
                            font-size: 24px;
                            margin: 0 0 10px 0;
                        }
                        p {
                            font-size: 16px;
                            opacity: 0.9;
                            margin: 0 0 20px 0;
                        }
                        .author {
                            font-size: 14px;
                            opacity: 0.7;
                            margin-bottom: 20px;
                        }
                        .button {
                            display: inline-block;
                            background: white;
                            color: #667eea;
                            padding: 15px 30px;
                            border-radius: 30px;
                            text-decoration: none;
                            font-weight: bold;
                            font-size: 16px;
                            transition: transform 0.2s;
                        }
                        .button:hover {
                            transform: scale(1.05);
                        }
                        .store-links {
                            margin-top: 20px;
                            font-size: 14px;
                            opacity: 0.8;
                        }
                        .store-links a {
                            color: white;
                            text-decoration: underline;
                        }
                    </style>

                    <script>
                        // Try to open the app, fallback to store
                        function openApp() {
                            var deepLink = '%s';
                            var fallbackUrl = 'https://play.google.com/store/apps/details?id=com.cookstemma.app';

                            // Try deep link
                            window.location.href = deepLink;

                            // Fallback after timeout
                            setTimeout(function() {
                                window.location.href = fallbackUrl;
                            }, 2000);
                        }
                    </script>
                </head>
                <body>
                    <div class="container">
                        <img src="%s" alt="%s">
                        <h1>%s</h1>
                        <p>%s</p>
                        <div class="author">by %s</div>
                        <a href="javascript:openApp()" class="button">앱에서 보기</a>
                        <div class="store-links">
                            앱이 없으신가요? <a href="https://play.google.com/store/apps/details?id=com.cookstemma.app">다운로드</a>
                        </div>
                    </div>
                </body>
                </html>
                """.formatted(
                title,           // page title
                shareUrl,        // og:url
                title,           // og:title
                description,     // og:description
                imageUrl,        // og:image
                shareUrl,        // twitter:url
                title,           // twitter:title
                description,     // twitter:description
                imageUrl,        // twitter:image
                deepLink,        // al:android:url
                deepLink,        // al:ios:url
                deepLink,        // javascript openApp
                imageUrl,        // img src
                title,           // img alt
                title,           // h1
                description,     // p
                userName      // author
        );
    }

    /**
     * Generate a 404 page for recipes that don't exist.
     */
    private String generateNotFoundHtml() {
        return """
                <!DOCTYPE html>
                <html lang="ko">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>레시피를 찾을 수 없습니다 - Cookstemma</title>
                    <meta property="og:title" content="레시피를 찾을 수 없습니다">
                    <meta property="og:description" content="요청하신 레시피가 존재하지 않거나 삭제되었습니다.">
                    <style>
                        body {
                            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                            display: flex;
                            align-items: center;
                            justify-content: center;
                            min-height: 100vh;
                            margin: 0;
                            background: #f5f5f5;
                            text-align: center;
                        }
                        h1 { color: #333; }
                        p { color: #666; }
                    </style>
                </head>
                <body>
                    <div>
                        <h1>레시피를 찾을 수 없습니다</h1>
                        <p>요청하신 레시피가 존재하지 않거나 삭제되었습니다.</p>
                    </div>
                </body>
                </html>
                """;
    }

    /**
     * Get the creator name for a recipe.
     */
    private String getCreatorName(Recipe recipe) {
        if (recipe.getCreatorId() == null) {
            return "Cookstemma";
        }
        return userRepository.findById(recipe.getCreatorId())
                .map(user -> user.getUsername())
                .orElse("Cookstemma");
    }

    /**
     * Get the image URL for a recipe, or default if none.
     */
    private String getImageUrl(Recipe recipe) {
        // Get cover image from recipe's images (via join table)
        return recipe.getCoverImages().stream()
                .filter(img -> img.getType() == ImageType.COVER)
                .findFirst()
                .map(img -> {
                    String filename = img.getStoredFilename();
                    if (filename != null && !filename.startsWith("http")) {
                        return imageUrlPrefix + "/" + filename;
                    }
                    return filename;
                })
                .orElse(DEFAULT_IMAGE);
    }

    /**
     * Truncate text to max length with ellipsis.
     */
    private String truncate(String text, int maxLength) {
        if (text == null) return "";
        if (text.length() <= maxLength) return text;
        return text.substring(0, maxLength - 3) + "...";
    }
}
