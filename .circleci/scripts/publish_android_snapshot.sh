#!/usr/bin/env bash
# Safe Android Gradle upload script
# DO NOT ADD 'set -x' to avoid revealing CircleCI secrets
set -eu -o pipefail

# debug tracing (optional)
[[ "${DEBUG:-}" == "1" ]] && set -x

# Configurable paths
WORKSPACE="${WORKSPACE:-$HOME/workspace}"
ANDROID_HOME="${ANDROID_HOME:-/opt/android/sdk}"
ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-/opt/ndk}"
GRADLE_VERSION="${GRADLE_VERSION:-6.8.3}"
GRADLE_HOME="${GRADLE_HOME:-/opt/gradle/gradle-$GRADLE_VERSION}"
GRADLE_PATH="${GRADLE_PATH:-$GRADLE_HOME/bin/gradle}"

GRADLE_PROPERTIES="$WORKSPACE/android/gradle.properties"
LOCAL_PROPERTIES="$WORKSPACE/android/local.properties"

echo "BUILD_ENVIRONMENT: ${BUILD_ENVIRONMENT:-undefined}"
ls -la "$WORKSPACE"

# Snapshot version checker
if ! grep -q 'VERSION_NAME=[0-9\.]\+-SNAPSHOT' "$GRADLE_PROPERTIES"; then
    echo "Error: version is not snapshot."
    exit 1
fi

# Check environment variables
required_vars=(SONATYPE_NEXUS_USERNAME SONATYPE_NEXUS_PASSWORD ANDROID_SIGN_KEY ANDROID_SIGN_PASS)
for v in "${required_vars[@]}"; do
    if [ -z "${!v:-}" ]; then
        echo "Error: missing environment variable $v"
        exit 1
    fi
done

cat > "$LOCAL_PROPERTIES" <<EOF
sdk.dir=$ANDROID_HOME
ndk.dir=$ANDROID_NDK_HOME
EOF

# Create a temp file first for atomic update
TMP_GRADLE_PROPERTIES="$(mktemp "$GRADLE_PROPERTIES.XXXXXX")"
trap 'rm -f "$TMP_GRADLE_PROPERTIES"' EXIT

cat > "$TMP_GRADLE_PROPERTIES" <<EOF
SONATYPE_NEXUS_USERNAME=${SONATYPE_NEXUS_USERNAME}
mavenCentralRepositoryUsername=${SONATYPE_NEXUS_USERNAME}
SONATYPE_NEXUS_PASSWORD=${SONATYPE_NEXUS_PASSWORD}
mavenCentralRepositoryPassword=${SONATYPE_NEXUS_PASSWORD}
signing.keyId=${ANDROID_SIGN_KEY}
signing.password=${ANDROID_SIGN_PASS}
EOF

mv -- "$TMP_GRADLE_PROPERTIES" "$GRADLE_PROPERTIES"
trap - EXIT

if [ ! -x "$GRADLE_PATH" ]; then
    echo "Error: Gradle executable not found at $GRADLE_PATH"
    exit 1
fi

"$GRADLE_PATH" -p "$WORKSPACE/android" uploadArchives

echo "Upload completed successfully."
