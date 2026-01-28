# Firebase Configuration Setup

This directory contains Firebase configuration files for different environments.

## Directory Structure

```
Firebase/
├── README.md                          # This file
├── GoogleService-Info-template.plist  # Template reference
├── Dev/
│   └── GoogleService-Info.plist       # Dev config (gitignored)
└── Prod/
    └── GoogleService-Info.plist       # Prod config (gitignored)

Configurations/
├── Dev.xcconfig                       # Dev build settings (tracked with placeholder)
└── Prod.xcconfig                      # Prod build settings (tracked with placeholder)
```

## Local Development Setup

### 1. Download Firebase Config Files

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select the appropriate project:
   - **Dev**: `cookstemma-dev`
   - **Prod**: `cookstemma-prod`
3. Go to **Project Settings** → **General**
4. Under "Your apps", find the iOS app
5. Click **Download GoogleService-Info.plist**

### 2. Place Config Files

```bash
# For Dev environment
cp ~/Downloads/GoogleService-Info.plist ios/Firebase/Dev/

# For Prod environment (if needed locally)
cp ~/Downloads/GoogleService-Info.plist ios/Firebase/Prod/
```

### 3. Update xcconfig Files

Edit the xcconfig files with your REVERSED_CLIENT_ID from GoogleService-Info.plist:

```bash
# Edit ios/Configurations/Dev.xcconfig
# Replace PLACEHOLDER_DEV_CLIENT_ID with your actual value
# e.g., REVERSED_CLIENT_ID = com.googleusercontent.apps.946572066572-xxxxxxxxxxxx
```

Find REVERSED_CLIENT_ID in your GoogleService-Info.plist file.

### 4. Prevent Git From Tracking Local Changes (Optional)

```bash
git update-index --skip-worktree ios/Configurations/Dev.xcconfig
git update-index --skip-worktree ios/Configurations/Prod.xcconfig
```

### 5. Select the Right Scheme in Xcode

- **Cookstemma-Dev**: For development
- **Cookstemma-Prod**: For production

## GitHub Actions Setup

Add these secrets to your GitHub repository (Settings → Secrets → Actions):

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `GOOGLE_SERVICE_INFO_DEV` | Base64-encoded Dev plist | See below |
| `GOOGLE_SERVICE_INFO_PROD` | Base64-encoded Prod plist | See below |
| `REVERSED_CLIENT_ID_DEV` | Dev REVERSED_CLIENT_ID | From plist file |
| `REVERSED_CLIENT_ID_PROD` | Prod REVERSED_CLIENT_ID | From plist file |

### How to Create Base64 Secret

```bash
# macOS
base64 -i ios/Firebase/Dev/GoogleService-Info.plist | tr -d '\n' | pbcopy
# Paste into GitHub Secrets as GOOGLE_SERVICE_INFO_DEV

# Linux
base64 -w 0 ios/Firebase/Dev/GoogleService-Info.plist
# Copy output to GitHub Secrets
```

### Getting REVERSED_CLIENT_ID

Open your GoogleService-Info.plist and find:
```xml
<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.946572066572-xxxxxxxxxxxxxxxxxxxxxxx</string>
```

Copy the value (e.g., `com.googleusercontent.apps.946572066572-xxx`) to the GitHub secret.

## Build Configurations

| Scheme | Config | Bundle ID | Environment |
|--------|--------|-----------|-------------|
| Cookstemma-Dev | Debug-Dev | com.cookstemma.app.dev | Development |
| Cookstemma-Dev | Release-Dev | com.cookstemma.app.dev | Development |
| Cookstemma-Prod | Debug-Prod | com.cookstemma.app | Production |
| Cookstemma-Prod | Release-Prod | com.cookstemma.app | Production |

## Troubleshooting

### "notConfigured" Error on Google Sign-In

This means Firebase can't find the CLIENT_ID. Check:
1. GoogleService-Info.plist exists in `Firebase/Dev/` (or Prod)
2. The plist contains a `CLIENT_ID` key (not placeholder values)
3. You're using the correct scheme (Cookstemma-Dev or Cookstemma-Prod)
4. REVERSED_CLIENT_ID in xcconfig matches your plist

### Build Script Error: "GoogleService-Info.plist not found"

1. Verify the file exists in the correct Firebase subdirectory
2. Check you selected the right scheme for your environment
3. Run `xcodegen generate` if you changed project.yml

### URL Scheme Not Working

Ensure the REVERSED_CLIENT_ID in your xcconfig matches exactly what's in GoogleService-Info.plist.
