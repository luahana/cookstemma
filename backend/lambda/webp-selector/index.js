'use strict';

/**
 * Lambda@Edge function for automatic WebP format selection.
 * Runs at CloudFront origin-request to serve WebP images to browsers that support it.
 *
 * How it works:
 * 1. Client requests: /images/variants/LARGE_1200/photo.jpg
 * 2. Lambda checks Accept header for image/webp support
 * 3. If supported, rewrites to: /images/variants/LARGE_1200/photo.webp
 * 4. CloudFront fetches WebP from origin (if exists)
 */

exports.handler = async (event) => {
    const request = event.Records[0].cf.request;
    const headers = request.headers;

    // Only process image requests in variants folder
    if (!request.uri.includes('/variants/')) {
        return request;
    }

    // Check if request is for a JPEG image
    if (!request.uri.match(/\.(jpg|jpeg)$/i)) {
        return request;
    }

    // Check Accept header for WebP support
    const acceptHeader = headers['accept'] ? headers['accept'][0].value : '';
    const supportsWebP = acceptHeader.includes('image/webp');

    if (supportsWebP) {
        // Rewrite URI to WebP version
        request.uri = request.uri.replace(/\.(jpg|jpeg)$/i, '.webp');

        // Add custom header to track the rewrite (for debugging/logging)
        request.headers['x-webp-rewrite'] = [{ key: 'X-WebP-Rewrite', value: 'true' }];
    }

    return request;
};
