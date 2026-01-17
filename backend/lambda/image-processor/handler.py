"""
Image Processing Lambda Handler
Generates image variants (resized JPEG/WebP) from original uploads.
Triggered by Step Functions for parallel processing.
"""
import json
import logging
import os
import tempfile
import uuid
from io import BytesIO
from typing import Any

import boto3
from PIL import Image

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
secrets_client = boto3.client('secretsmanager')

# Cache for secrets
_secrets_cache: dict[str, Any] = {}

# Variant configurations
VARIANTS = {
    'LARGE_1200': {'max_size': 1200, 'quality': 85},
    'MEDIUM_800': {'max_size': 800, 'quality': 80},
    'THUMB_400': {'max_size': 400, 'quality': 75},
    'THUMB_200': {'max_size': 200, 'quality': 70},
}

SUPPORTED_FORMATS = ['JPEG', 'WEBP']


def get_secret(secret_name: str) -> dict:
    """Retrieve and cache secrets from AWS Secrets Manager."""
    if secret_name not in _secrets_cache:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        _secrets_cache[secret_name] = json.loads(response['SecretString'])
    return _secrets_cache[secret_name]


def download_from_s3(bucket: str, key: str) -> bytes:
    """Download file from S3."""
    response = s3_client.get_object(Bucket=bucket, Key=key)
    return response['Body'].read()


def upload_to_s3(bucket: str, key: str, data: bytes, content_type: str) -> dict:
    """Upload file to S3 and return metadata."""
    s3_client.put_object(
        Bucket=bucket,
        Key=key,
        Body=data,
        ContentType=content_type,
        CacheControl='max-age=31536000'  # 1 year cache
    )
    return {
        'bucket': bucket,
        'key': key,
        'size': len(data),
        'content_type': content_type
    }


def resize_image(image: Image.Image, max_size: int) -> Image.Image:
    """Resize image maintaining aspect ratio."""
    width, height = image.size

    if width <= max_size and height <= max_size:
        return image.copy()

    if width > height:
        new_width = max_size
        new_height = int(height * (max_size / width))
    else:
        new_height = max_size
        new_width = int(width * (max_size / height))

    return image.resize((new_width, new_height), Image.Resampling.LANCZOS)


def convert_to_format(image: Image.Image, format: str, quality: int) -> tuple[bytes, str]:
    """Convert image to specified format and return bytes + content type."""
    output = BytesIO()

    # Ensure RGB mode for JPEG (no alpha channel)
    if format == 'JPEG' and image.mode in ('RGBA', 'P'):
        image = image.convert('RGB')

    if format == 'WEBP':
        image.save(output, format='WEBP', quality=quality, method=6)
        content_type = 'image/webp'
    else:
        image.save(output, format='JPEG', quality=quality, optimize=True)
        content_type = 'image/jpeg'

    return output.getvalue(), content_type


def generate_variant_key(original_key: str, variant_name: str, format: str) -> str:
    """Generate S3 key for variant image."""
    # Original: images/abc123.jpg
    # Variant: images/variants/LARGE_1200/abc123.jpg (or .webp)
    parts = original_key.rsplit('/', 1)
    if len(parts) == 2:
        prefix, filename = parts
    else:
        prefix = ''
        filename = original_key

    # Change extension for WebP
    name, _ = os.path.splitext(filename)
    new_ext = '.webp' if format == 'WEBP' else '.jpg'

    if prefix:
        return f"{prefix}/variants/{variant_name}/{name}{new_ext}"
    return f"variants/{variant_name}/{name}{new_ext}"


def process_single_variant(
    original_image: Image.Image,
    bucket: str,
    original_key: str,
    variant_name: str,
    format: str
) -> dict:
    """Process a single variant and upload to S3."""
    config = VARIANTS[variant_name]

    # Resize
    resized = resize_image(original_image, config['max_size'])

    # Convert to target format
    data, content_type = convert_to_format(resized, format, config['quality'])

    # Generate key and upload
    variant_key = generate_variant_key(original_key, variant_name, format)
    upload_result = upload_to_s3(bucket, variant_key, data, content_type)

    return {
        'variant_name': variant_name,
        'format': format,
        'width': resized.width,
        'height': resized.height,
        'file_size': len(data),
        's3_key': variant_key,
        's3_bucket': bucket
    }


def handler(event: dict, context) -> dict:
    """
    Lambda handler for image variant generation.

    Event structure (from Step Functions):
    {
        "bucket": "my-bucket",
        "key": "images/original/abc123.jpg",
        "variant": "LARGE_1200",  // or "ALL" for all variants
        "format": "JPEG",         // or "WEBP" or "ALL"
        "image_id": 123,          // Database image ID (optional)
        "public_id": "uuid"       // Public ID for tracking
    }

    For Step Functions parallel processing, each state passes specific variant+format.
    """
    logger.info(f"Image processor invoked with event: {json.dumps(event)}")

    try:
        bucket = event['bucket']
        key = event['key']
        variant = event.get('variant', 'ALL')
        format_type = event.get('format', 'ALL')
        image_id = event.get('image_id')
        public_id = event.get('public_id', str(uuid.uuid4()))

        # Download original image
        logger.info(f"Downloading original image: s3://{bucket}/{key}")
        image_data = download_from_s3(bucket, key)
        original_image = Image.open(BytesIO(image_data))

        # Get original dimensions
        original_width, original_height = original_image.size
        logger.info(f"Original image size: {original_width}x{original_height}")

        results = []

        # Determine which variants to process
        variants_to_process = [variant] if variant != 'ALL' else list(VARIANTS.keys())
        formats_to_process = [format_type] if format_type != 'ALL' else SUPPORTED_FORMATS

        for var_name in variants_to_process:
            if var_name not in VARIANTS:
                logger.warning(f"Unknown variant: {var_name}")
                continue

            for fmt in formats_to_process:
                if fmt not in SUPPORTED_FORMATS:
                    logger.warning(f"Unknown format: {fmt}")
                    continue

                logger.info(f"Processing variant: {var_name} in {fmt} format")
                result = process_single_variant(
                    original_image, bucket, key, var_name, fmt
                )
                result['public_id'] = public_id
                result['image_id'] = image_id
                results.append(result)
                logger.info(f"Generated: {result['s3_key']} ({result['width']}x{result['height']}, {result['file_size']} bytes)")

        response = {
            'statusCode': 200,
            'public_id': public_id,
            'image_id': image_id,
            'original': {
                'bucket': bucket,
                'key': key,
                'width': original_width,
                'height': original_height
            },
            'variants': results,
            'variants_count': len(results)
        }

        logger.info(f"Image processing complete: {len(results)} variants generated")
        return response

    except Exception as e:
        logger.error(f"Image processing error: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'error': str(e),
            'public_id': event.get('public_id'),
            'image_id': event.get('image_id')
        }


def orchestrator_handler(event: dict, context) -> dict:
    """
    Orchestrator handler - receives S3 event and prepares work for Step Functions.

    Event structure (from S3 via EventBridge):
    {
        "detail": {
            "bucket": {"name": "my-bucket"},
            "object": {"key": "images/original/abc123.jpg"}
        }
    }

    Returns tasks for Step Functions to process in parallel.
    """
    logger.info(f"Orchestrator invoked with event: {json.dumps(event)}")

    try:
        # Extract S3 info from EventBridge event
        if 'detail' in event:
            bucket = event['detail']['bucket']['name']
            key = event['detail']['object']['key']
        elif 'Records' in event:
            # Direct S3 event
            record = event['Records'][0]
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']
        else:
            # Direct invocation
            bucket = event['bucket']
            key = event['key']

        public_id = event.get('public_id', str(uuid.uuid4()))
        image_id = event.get('image_id')

        # Skip if this is already a variant
        if '/variants/' in key:
            logger.info(f"Skipping variant image: {key}")
            return {'statusCode': 200, 'message': 'Skipped variant image'}

        # Prepare tasks for parallel processing
        tasks = []
        for variant_name in VARIANTS.keys():
            for format_type in SUPPORTED_FORMATS:
                tasks.append({
                    'bucket': bucket,
                    'key': key,
                    'variant': variant_name,
                    'format': format_type,
                    'public_id': public_id,
                    'image_id': image_id
                })

        return {
            'statusCode': 200,
            'bucket': bucket,
            'key': key,
            'public_id': public_id,
            'image_id': image_id,
            'tasks': tasks,
            'task_count': len(tasks)
        }

    except Exception as e:
        logger.error(f"Orchestrator error: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'error': str(e)
        }
