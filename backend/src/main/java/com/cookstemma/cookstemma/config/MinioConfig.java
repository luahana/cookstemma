package com.cookstemma.cookstemma.config;

import io.minio.BucketExistsArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.SetBucketPolicyArgs;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Configuration
@Profile("dev")
public class MinioConfig {

    // application-dev.yml의 구조에 맞게 경로 수정
    @Value("${spring.cloud.aws.s3.endpoint}")
    private String endpoint;

    @Value("${spring.cloud.aws.credentials.access-key}")
    private String accessKey;

    @Value("${spring.cloud.aws.credentials.secret-key}")
    private String secretKey;

    @Value("${file.upload.bucket}")
    private String bucketName;

    @Bean
    public MinioClient minioClient() {
        try {
            MinioClient minioClient = MinioClient.builder()
                    .endpoint(endpoint)
                    .credentials(accessKey, secretKey)
                    .build();

            // 버킷 생성 및 Public 정책 적용
            initBucketPolicy(minioClient);

            return minioClient;
        } catch (Exception e) {
            throw new RuntimeException("MinIO 연결 및 정책 설정 실패: " + e.getMessage());
        }
    }

    private void initBucketPolicy(MinioClient minioClient) throws Exception {
        // 1. 버킷이 없으면 생성
        boolean found = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucketName).build());
        if (!found) {
            minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucketName).build());
        }

        // 2. Public Read-Only 정책 설정 (익명 사용자가 이미지를 볼 수 있게 허용)
        String policy = "{\n" +
                "  \"Version\": \"2012-10-17\",\n" +
                "  \"Statement\": [\n" +
                "    {\n" +
                "      \"Effect\": \"Allow\",\n" +
                "      \"Principal\": {\"AWS\": [\"*\"]},\n" +
                "      \"Action\": [\"s3:GetBucketLocation\", \"s3:ListBucket\"],\n" +
                "      \"Resource\": [\"arn:aws:s3:::" + bucketName + "\"]\n" +
                "    },\n" +
                "    {\n" +
                "      \"Effect\": \"Allow\",\n" +
                "      \"Principal\": {\"AWS\": [\"*\"]},\n" +
                "      \"Action\": [\"s3:GetObject\"],\n" +
                "      \"Resource\": [\"arn:aws:s3:::" + bucketName + "/*\"]\n" +
                "    }\n" +
                "  ]\n" +
                "}";

        minioClient.setBucketPolicy(
                SetBucketPolicyArgs.builder().bucket(bucketName).config(policy).build()
        );
    }
}