#!/bin/bash

# Runs Maestro mobile E2E flows. Arguments use the param:value convention
# (same contract as robot-internal.sh), e.g.:
#   maestro-internal.sh platform:ios flow:chat_from_games,edit_game
#
# Project-specific values are NOT hardcoded here; they must be provided as
# environment variables, normally defined in custom-config/<host|user>.sh
# (sourced automatically by environment-variables.sh):
#   MAESTRO_APP_ID       (required) bundle/package id of the app under test
#   MAESTRO_MOBILE_PATH  (required) mobile app root folder
#   MAESTRO_METRO_PORT   (optional) Metro bundler port, default 8081

# Exit immediately if a command exits with a non-zero status
set -e

# Save the current directory and change to the script's directory
pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null

# Source the environment variables script
source ./environment-variables.sh

# Print an error and abort the run
fail() {
  source "$CONSOLE_TOOLS_PATH/error.sh" "$@"
  exit 1
}

# Parse command-line arguments and set environment variables
for arg in "$@"; do
  IFS=':' read -r key value <<< "$arg"
  export "$key"="$value"
done

# Set default environment variables if not already set
platform="${platform:-android}"
flow="${flow:-}"
includetags="${includetags:-}"
excludetags="${excludetags:-}"
device="${device:-}"
debug="${debug:-false}"
format="${format:-junit}"
MAESTRO_METRO_PORT="${MAESTRO_METRO_PORT:-8081}"

# Validate required project configuration
if [ -z "${MAESTRO_APP_ID:-}" ]; then
  fail "MAESTRO_APP_ID is not set. Define it in custom-config/<host|user>.sh (e.g. MAESTRO_APP_ID=com.example.app)"
fi
if [ -z "${MAESTRO_MOBILE_PATH:-}" ]; then
  fail "MAESTRO_MOBILE_PATH is not set. Define it in custom-config/<host|user>.sh (e.g. MAESTRO_MOBILE_PATH=\$PROJECT_ROOT/mobile)"
fi
if [ ! -d "$MAESTRO_MOBILE_PATH" ]; then
  fail "MAESTRO_MOBILE_PATH does not exist: $MAESTRO_MOBILE_PATH"
fi

# Validate platform
case "$platform" in
  android) ;;
  ios)
    if [ "$(uname -s)" != "Darwin" ]; then
      fail "platform:ios requires macOS (iOS Simulator)"
    fi
    ;;
  *)
    fail "Unsupported platform '$platform'. Valid values: android, ios"
    ;;
esac

# Validate report format; junit additionally post-generates an HTML viewer
format=$(echo "$format" | tr '[:upper:]' '[:lower:]')
case "$format" in
  junit|html|html-detailed) ;;
  *)
    fail "Unsupported format '$format'. Valid values: junit, html, html-detailed"
    ;;
esac
maestro_format=$(echo "$format" | tr '[:lower:]' '[:upper:]')

# Resolve flow names against the flows directory; fail fast on unknown names
FLOWS_DIR="$MAESTRO_MOBILE_PATH/.maestro/flows"
if [ ! -d "$FLOWS_DIR" ]; then
  fail "Flows directory not found: $FLOWS_DIR"
fi

flow_targets=()
if [ -n "$flow" ]; then
  IFS=',' read -ra flow_names <<< "$flow"
  for name in "${flow_names[@]}"; do
    if [ -z "$name" ]; then
      continue
    fi
    candidate="$FLOWS_DIR/$name"
    if [ ! -f "$candidate" ]; then
      if [ -f "$candidate.yaml" ]; then
        candidate="$candidate.yaml"
      elif [ -f "$candidate.yml" ]; then
        candidate="$candidate.yml"
      else
        fail "Flow not found: '$name' (looked for $FLOWS_DIR/${name}[.yaml|.yml])"
      fi
    fi
    flow_targets+=("$candidate")
  done
  if [ "${#flow_targets[@]}" -eq 0 ]; then
    fail "No valid flows resolved from 'flow:$flow'"
  fi
else
  flow_targets=("$FLOWS_DIR/")
fi

# Result locations follow the build convention (.temp/<tool>-results)
MAESTRO_RESULTS_PATH="$BUILD_TEMP_FOLDER/maestro-results"
HTML_REPORT_FILE="$MAESTRO_RESULTS_PATH/maestro-report_${platform}.html"
if [ "$format" == "junit" ]; then
  REPORT_FILE="$MAESTRO_RESULTS_PATH/maestro-junit_${platform}.xml"
else
  REPORT_FILE="$HTML_REPORT_FILE"
fi
ARTIFACT_DIR="$MAESTRO_RESULTS_PATH/artifacts"
rm -rf "$MAESTRO_RESULTS_PATH"
mkdir -p "$ARTIFACT_DIR"

# Silence the JDK 24+ "restricted method ... native access" warnings emitted
# by Maestro's bundled jansi; forwarded to the JVM by Maestro's launcher.
export JAVA_OPTS="${JAVA_OPTS:-} --enable-native-access=ALL-UNNAMED"

# State for the cleanup handler
METRO_PID=""
EMULATOR_STARTED="false"
AUTOFILL_SERVICE_DISABLED="false"
SAVED_AUTOFILL_SERVICE=""

cleanup() {
  if [ -n "$METRO_PID" ]; then
    echo "Stopping Metro bundler (PID $METRO_PID)..."
    kill "$METRO_PID" 2>/dev/null || true
    wait "$METRO_PID" 2>/dev/null || true
  fi
  # Restore the device autofill service we disabled for the run
  if [ "$AUTOFILL_SERVICE_DISABLED" == "true" ]; then
    echo "Restoring Android autofill service..."
    if [ -n "$SAVED_AUTOFILL_SERVICE" ] && [ "$SAVED_AUTOFILL_SERVICE" != "null" ]; then
      adb shell settings put secure autofill_service "$SAVED_AUTOFILL_SERVICE" 2>/dev/null || true
    else
      adb shell settings delete secure autofill_service 2>/dev/null || true
    fi
  fi
  if [ "$EMULATOR_STARTED" == "true" ]; then
    echo "Stopping emulator..."
    adb emu kill 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

# =============================================================================
# Common preflight checks
# =============================================================================
source ./subtitle.sh "Maestro preflight checks ($platform)"

ENV_FILE="$MAESTRO_MOBILE_PATH/.env.maestro"
if [ ! -f "$ENV_FILE" ]; then
  fail "$ENV_FILE not found. Copy .env.maestro.example and fill in credentials"
fi

# Locate Maestro CLI (native install, home install, or inside WSL on Windows)
MAESTRO_BIN=""
MAESTRO_VIA_WSL="false"
WSL_CMD=""
if command -v maestro > /dev/null 2>&1; then
  MAESTRO_BIN="maestro"
elif [ -x "$HOME/.maestro/bin/maestro" ]; then
  MAESTRO_BIN="$HOME/.maestro/bin/maestro"
elif command -v wsl.exe > /dev/null 2>&1 || command -v wsl > /dev/null 2>&1; then
  # On Windows (Git Bash/MSYS), check if Maestro is installed inside WSL.
  # MSYS_NO_PATHCONV=1 prevents Git Bash from mangling Unix-style paths.
  WSL_CMD=$(command -v wsl.exe 2>/dev/null || command -v wsl 2>/dev/null)
  WSL_MAESTRO_PATH=$(MSYS_NO_PATHCONV=1 "$WSL_CMD" -e bash -l -c "command -v maestro 2>/dev/null || echo \${HOME}/.maestro/bin/maestro" 2>/dev/null | tr -d '\r')
  # "wsl.exe -e test -x <path>" doesn't propagate exit codes to Git Bash,
  # so the check is wrapped in "bash -c" which handles it correctly.
  if MSYS_NO_PATHCONV=1 "$WSL_CMD" -e bash -c "test -x '$WSL_MAESTRO_PATH'" 2>/dev/null; then
    MAESTRO_VIA_WSL="true"
    MAESTRO_BIN="$WSL_MAESTRO_PATH"
  fi
fi
if [ -z "$MAESTRO_BIN" ]; then
  fail "Maestro not found. Install it: curl -Ls \"https://get.maestro.mobile.dev\" | bash"
fi
echo "Maestro found at $MAESTRO_BIN (WSL: $MAESTRO_VIA_WSL)"

# Maestro requires Java (skip check when running via WSL - Java lives inside WSL)
if [ "$MAESTRO_VIA_WSL" == "false" ] && ! java -version > /dev/null 2>&1; then
  if command -v brew > /dev/null 2>&1; then
    echo "Java Runtime not found. Installing OpenJDK via Homebrew..."
    brew install --quiet openjdk
    # Create the symlink so /usr/libexec/java_home and java wrappers find it
    jdk_path="$(brew --prefix openjdk)/libexec/openjdk.jdk"
    if [ -d "$jdk_path" ]; then
      sudo ln -sfn "$jdk_path" /Library/Java/JavaVirtualMachines/openjdk.jdk 2>/dev/null || true
    fi
    openjdk_prefix="$(brew --prefix openjdk)"
    export PATH="$openjdk_prefix/bin:$PATH"
    if ! java -version > /dev/null 2>&1; then
      fail "Java installation failed. Install manually: brew install openjdk"
    fi
    echo "OpenJDK installed"
  else
    fail "Java Runtime not found. Maestro requires Java; install from https://adoptium.net"
  fi
fi

# =============================================================================
# Platform-specific preflight checks
# =============================================================================
preflight_android() {
  # Auto-detect Android SDK and add platform-tools/emulator to PATH
  if ! command -v adb > /dev/null 2>&1; then
    local android_sdk=""
    local candidate
    for candidate in \
      "${ANDROID_HOME:-}" \
      "${ANDROID_SDK_ROOT:-}" \
      "${LOCALAPPDATA:-}/Android/Sdk" \
      "$HOME/AppData/Local/Android/Sdk" \
      "$HOME/Library/Android/sdk" \
      "$HOME/Android/Sdk"; do
      if [ -n "$candidate" ] && [ -d "$candidate/platform-tools" ]; then
        android_sdk="$candidate"
        break
      fi
    done
    if [ -n "$android_sdk" ]; then
      echo "Auto-detected Android SDK at $android_sdk"
      export PATH="$android_sdk/platform-tools:$android_sdk/emulator:$PATH"
    fi
  fi

  if ! command -v adb > /dev/null 2>&1; then
    fail "adb not found in PATH"
  fi

  # Check for a connected device, launch an emulator if needed
  local device_count
  device_count=$(adb devices | grep -cw "device" || true)
  if [ "$device_count" -lt 1 ]; then
    echo "No Android device/emulator connected. Attempting to launch one..."

    local emulator_bin=""
    if command -v emulator > /dev/null 2>&1; then
      emulator_bin="emulator"
    elif [ -n "${ANDROID_HOME:-}" ] && [ -x "$ANDROID_HOME/emulator/emulator" ]; then
      emulator_bin="$ANDROID_HOME/emulator/emulator"
    elif [ -n "${ANDROID_SDK_ROOT:-}" ] && [ -x "$ANDROID_SDK_ROOT/emulator/emulator" ]; then
      emulator_bin="$ANDROID_SDK_ROOT/emulator/emulator"
    else
      fail "emulator binary not found. Set ANDROID_HOME or start an emulator manually"
    fi

    local avd_name
    avd_name=$("$emulator_bin" -list-avds | head -n 1)
    if [ -z "$avd_name" ]; then
      fail "No AVDs found. Create one in Android Studio first"
    fi

    echo "Starting emulator: $avd_name..."
    "$emulator_bin" -avd "$avd_name" -no-snapshot-save -no-audio -no-boot-anim > /dev/null 2>&1 &
    EMULATOR_STARTED="true"

    echo "Waiting for emulator to boot..."
    local i boot_completed
    for i in $(seq 1 120); do
      boot_completed=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
      if [ "$boot_completed" == "1" ]; then
        echo "Emulator booted"
        break
      fi
      if [ "$i" -eq 120 ]; then
        fail "Emulator did not boot within 120 seconds"
      fi
      sleep 1
    done
  else
    echo "Android device connected"
  fi

  # Disable the system autofill service for the run. Saved-password popups
  # cover the login inputs and fail the authenticated flows; the original
  # value is restored by the cleanup handler.
  SAVED_AUTOFILL_SERVICE=$(adb shell settings get secure autofill_service 2>/dev/null | tr -d '\r' || true)
  if [ "$SAVED_AUTOFILL_SERVICE" != "null" ]; then
    echo "Disabling Android autofill service (was: ${SAVED_AUTOFILL_SERVICE:-unset})..."
    if adb shell settings put secure autofill_service null 2>/dev/null; then
      AUTOFILL_SERVICE_DISABLED="true"
    else
      echo "WARNING: could not disable autofill service; saved-password popups may interfere"
    fi
  fi

  # Check that the app under test is installed
  if ! adb shell pm list packages 2>/dev/null | grep -q "$MAESTRO_APP_ID"; then
    fail "$MAESTRO_APP_ID not installed on device. Build and install the dev client APK first"
  fi
  echo "App $MAESTRO_APP_ID is installed on the device"
}

preflight_ios() {
  # xcrun must be available (implies Xcode is installed)
  if ! command -v xcrun > /dev/null 2>&1; then
    fail "xcrun not found. Install Xcode from the Mac App Store"
  fi

  # Check that at least one simulator is booted
  BOOTED_UDID=$(xcrun simctl list devices booted --json 2>/dev/null \
    | grep -o '"udid" : "[^"]*"' | head -1 | grep -o '[0-9A-F-]\{36\}' || true)
  if [ -z "$BOOTED_UDID" ]; then
    fail "No iOS Simulator is currently booted. Open Simulator.app, boot a device, and re-run"
  fi
  local booted_name
  booted_name=$(xcrun simctl list devices booted 2>/dev/null | grep -o '[^(]*' | head -1 | xargs || true)
  echo "Booted simulator: $booted_name ($BOOTED_UDID)"

  # Check that the app under test is installed on the booted simulator
  if ! xcrun simctl get_app_container "$BOOTED_UDID" "$MAESTRO_APP_ID" 2>/dev/null | grep -q "/"; then
    fail "$MAESTRO_APP_ID is not installed on the booted simulator. Build and install the dev client first"
  fi
  echo "App $MAESTRO_APP_ID is installed on the simulator"
}

if [ "$platform" == "android" ]; then
  preflight_android
else
  preflight_ios
fi

# =============================================================================
# Load test credentials from .env.maestro
# =============================================================================
MAESTRO_ENV_ARGS=()
E2E_DEV_API_HOST=""
while IFS='=' read -r key value; do
  # Skip comments and empty lines; strip Windows line endings
  if [ -z "$key" ] || [[ "$key" =~ ^# ]]; then
    continue
  fi
  value="${value//$'\r'/}"
  key="${key//$'\r'/}"
  # DEV_API_HOST is consumed by Metro, not passed to Maestro
  if [ "$key" == "DEV_API_HOST" ]; then
    E2E_DEV_API_HOST="$value"
    continue
  fi
  # The iOS Simulator always reaches Metro via localhost
  if [ "$key" == "METRO_HOST" ] && [ "$platform" == "ios" ]; then
    continue
  fi
  MAESTRO_ENV_ARGS+=("-e" "$key=$value")
done < "$ENV_FILE"

if [ "$platform" == "ios" ]; then
  MAESTRO_ENV_ARGS+=("-e" "METRO_HOST=localhost")
fi

if [ -z "$E2E_DEV_API_HOST" ]; then
  if [ "$platform" == "ios" ]; then
    E2E_DEV_API_HOST="localhost"
  else
    E2E_DEV_API_HOST="10.0.2.2"
  fi
  echo "DEV_API_HOST not set in .env.maestro, defaulting to $E2E_DEV_API_HOST ($platform)"
fi
echo "Backend API host for Metro: $E2E_DEV_API_HOST"

# Per-run identifier (mirrors the Robot suite's unique_identifier): flows tag
# the data they create with this token so each run's rows are identifiable
# for inspection/cleanup and repeated runs don't pile up duplicates.
MAESTRO_RUN_ID="$(date +%Y%m%d_%H%M%S)"
MAESTRO_ENV_ARGS+=("-e" "MAESTRO_RUN_ID=$MAESTRO_RUN_ID")

# =============================================================================
# Start Metro bundler in background (reuse a running instance)
# =============================================================================
if curl -s "http://localhost:$MAESTRO_METRO_PORT/status" 2>/dev/null | grep -q "packager-status:running"; then
  echo "Metro already running on port $MAESTRO_METRO_PORT, reusing it"
else
  source ./subtitle.sh "Starting Metro bundler on port $MAESTRO_METRO_PORT"
  pushd "$MAESTRO_MOBILE_PATH" > /dev/null
  # --localhost ensures Metro advertises 127.0.0.1, which the iOS Simulator
  # can always reach; Android emulators reach the host via 10.0.2.2 instead.
  metro_flags=(--port "$MAESTRO_METRO_PORT")
  if [ "$platform" == "ios" ]; then
    metro_flags+=(--localhost)
  fi
  DEV_API_HOST="$E2E_DEV_API_HOST" npx expo start "${metro_flags[@]}" > /dev/null 2>&1 &
  METRO_PID=$!
  popd > /dev/null

  echo "Waiting for Metro to be ready..."
  for i in $(seq 1 60); do
    if curl -s "http://localhost:$MAESTRO_METRO_PORT/status" 2>/dev/null | grep -q "packager-status:running"; then
      echo "Metro is ready"
      break
    fi
    if [ "$i" -eq 60 ]; then
      fail "Metro did not start within 60 seconds"
    fi
    sleep 1
  done
fi

# =============================================================================
# Run Maestro flows
# =============================================================================
source ./subtitle.sh "Running Maestro flows"

# Display configuration
echo "Platform: $platform"
echo "Flows: ${flow:-(all)}"
echo "Include tags: ${includetags:-(none)}"
echo "Exclude tags: ${excludetags:-(none)}"
echo "Device: ${device:-(auto)}"
echo "Format: $format"
echo "Run id: $MAESTRO_RUN_ID"
echo

# Global options go before the "test" subcommand
maestro_global_args=()
if [ -n "$device" ]; then
  maestro_global_args+=(--device "$device")
fi

# --no-ansi          : linear log output so a stalled step is visible
# --format           : junit (machine-readable, for CI) or html/html-detailed
# --test-output-dir  : screenshots and other artifacts on failure
maestro_test_args=(--no-ansi --format "$maestro_format" --output "$REPORT_FILE" --test-output-dir "$ARTIFACT_DIR")
if [ -n "$includetags" ]; then
  maestro_test_args+=(--include-tags "$includetags")
fi
if [ -n "$excludetags" ]; then
  maestro_test_args+=(--exclude-tags "$excludetags")
fi
if [ "$debug" == "true" ]; then
  maestro_test_args+=(--debug-output "$ARTIFACT_DIR/debug")
fi

# Capture the exit code explicitly: under `set -e` a non-zero `maestro` exit
# would otherwise abort before the summary is reported.
EXIT_CODE=0
if [ "$MAESTRO_VIA_WSL" == "true" ]; then
  # Convert Git Bash paths (/c/Users/...) -> Windows (C:\...) -> WSL (/mnt/c/...)
  to_wsl_path() {
    local win_path
    win_path=$(cygpath -w "$1" 2>/dev/null)
    MSYS_NO_PATHCONV=1 "$WSL_CMD" -e wslpath -u "$win_path" 2>/dev/null | tr -d '\r'
  }
  wsl_report_file=$(to_wsl_path "$REPORT_FILE")
  wsl_artifact_dir=$(to_wsl_path "$ARTIFACT_DIR")
  wsl_flow_args=""
  for target in "${flow_targets[@]}"; do
    wsl_flow_args+=" $(to_wsl_path "$target")"
  done
  wsl_test_args="--no-ansi --format $maestro_format --output $wsl_report_file --test-output-dir $wsl_artifact_dir"
  if [ -n "$includetags" ]; then
    wsl_test_args+=" --include-tags $includetags"
  fi
  if [ -n "$excludetags" ]; then
    wsl_test_args+=" --exclude-tags $excludetags"
  fi
  if [ "$debug" == "true" ]; then
    wsl_test_args+=" --debug-output $wsl_artifact_dir/debug"
  fi
  # MSYS_NO_PATHCONV=1 prevents Git Bash from mangling the -c argument paths
  MSYS_NO_PATHCONV=1 "$WSL_CMD" -e bash -l -c "$MAESTRO_BIN ${maestro_global_args[*]} test ${MAESTRO_ENV_ARGS[*]} $wsl_test_args $wsl_flow_args" || EXIT_CODE=$?
else
  "$MAESTRO_BIN" "${maestro_global_args[@]}" test "${maestro_test_args[@]}" "${MAESTRO_ENV_ARGS[@]}" "${flow_targets[@]}" || EXIT_CODE=$?
fi

# Post-generate an HTML viewer from the JUnit XML (mirrors the Robot chain's
# local metrics report) so a junit run yields both machine- and human-readable
# reports. Failures here only warn: the Maestro exit code stays authoritative.
if [ "$format" == "junit" ] && [ -f "$REPORT_FILE" ]; then
  venv_python=""
  for candidate in "$PYTHON_VENV/python3" "$PYTHON_VENV/python" "$PYTHON_VENV/python.exe"; do
    if [ -x "$candidate" ]; then
      venv_python="$candidate"
      break
    fi
  done
  # The Windows venv ships a native Python that cannot resolve MSYS paths
  report_in="$REPORT_FILE"
  report_out="$HTML_REPORT_FILE"
  if command -v cygpath > /dev/null 2>&1; then
    report_in=$(cygpath -m "$REPORT_FILE")
    report_out=$(cygpath -m "$HTML_REPORT_FILE")
  fi
  if [ -z "$venv_python" ]; then
    source ./warning.sh "Python venv not found at $PYTHON_VENV; skipping HTML report (run build/setup.sh)"
  elif ! "$venv_python" -m junit2htmlreport "$report_in" "$report_out" > /dev/null 2>&1; then
    source ./warning.sh "junit2html failed or is not installed; skipping HTML report (run build/setup.sh)"
  fi
fi

if [ "$EXIT_CODE" -eq 0 ]; then
  source ./subtitle-end.sh "All Maestro flows passed"
else
  source ./error.sh "Some Maestro flows failed (exit code $EXIT_CODE)"
fi
echo "Report: $REPORT_FILE"
if [ "$format" == "junit" ] && [ -f "$HTML_REPORT_FILE" ]; then
  echo "HTML report: $HTML_REPORT_FILE"
fi
echo "Test artifacts: $ARTIFACT_DIR"

popd > /dev/null

exit "$EXIT_CODE"
