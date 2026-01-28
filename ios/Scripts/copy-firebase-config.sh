#!/bin/bash

# Copy the correct GoogleService-Info.plist based on build configuration
# This script runs as a build phase in Xcode

set -e

FIREBASE_DIR="${PROJECT_DIR}/Firebase"
DESTINATION="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

# Determine environment from configuration name
if [[ "${CONFIGURATION}" == *"Prod"* ]] || [[ "${CONFIGURATION}" == "Release" ]]; then
    ENVIRONMENT="Prod"
else
    ENVIRONMENT="Dev"
fi

SOURCE_PLIST="${FIREBASE_DIR}/${ENVIRONMENT}/GoogleService-Info.plist"

echo "Configuration: ${CONFIGURATION}"
echo "Environment: ${ENVIRONMENT}"
echo "Source: ${SOURCE_PLIST}"
echo "Destination: ${DESTINATION}"

if [ ! -f "${SOURCE_PLIST}" ]; then
    echo "error: GoogleService-Info.plist not found at ${SOURCE_PLIST}"
    echo "error: Please download it from Firebase Console and place it in Firebase/${ENVIRONMENT}/"
    exit 1
fi

cp "${SOURCE_PLIST}" "${DESTINATION}"
echo "Successfully copied GoogleService-Info.plist for ${ENVIRONMENT} environment"
