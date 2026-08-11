#!/bin/bash

set -u
set -o pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
FIXTURE="$ROOT/tests/fixtures/mixed-country-cache.plist"
TEST_ROOT="$(mktemp -d /tmp/enableMacSiriAI-tests.XXXXXX)" || exit 1
PASS=0
FAIL=0

cleanup() {
    /usr/bin/chflags -R nouchg "$TEST_ROOT" 2>/dev/null || true
    /bin/chmod -R u+rwX "$TEST_ROOT" 2>/dev/null || true
    /bin/rm -rf "$TEST_ROOT"
}
trap cleanup EXIT HUP INT TERM

new_case() {
    CASE_DIR="$(mktemp -d "$TEST_ROOT/case.XXXXXX")"
    TARGET="$CASE_DIR/cache.plist"
    STATE="$CASE_DIR/state"
    LEGACY_STATE="$CASE_DIR/legacy-state"
    /bin/cp "$FIXTURE" "$TARGET"
    ORIGINAL_COPY="$CASE_DIR/expected-original.plist"
    /bin/cp "$FIXTURE" "$ORIGINAL_COPY"
}

ctl() {
    env \
      ENABLE_MAC_SIRI_AI_TEST_MODE=1 \
      ENABLE_MAC_SIRI_AI_TARGET="$TARGET" \
      ENABLE_MAC_SIRI_AI_STATE_DIR="$STATE" \
      ENABLE_MAC_SIRI_AI_LEGACY_STATE_DIR="$LEGACY_STATE" \
      ENABLE_MAC_SIRI_AI_OS_VERSION="${TEST_OS_VERSION:-27.0}" \
      ENABLE_MAC_SIRI_AI_ARCH="${TEST_ARCH:-arm64}" \
      ENABLE_MAC_SIRI_AI_REGION="${TEST_REGION:-LL/A}" \
      ENABLE_MAC_SIRI_AI_SKIP_SUDO=1 \
      ENABLE_MAC_SIRI_AI_SKIP_REFRESH=1 \
      "$ROOT/enableMacSiriAI" "$@"
}

pass() { PASS=$((PASS + 1)); printf 'ok %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'not ok %s\n' "$1" >&2; }

assert_contains() {
    case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

assert_source_line() {
    printf '%s\n' "$1" | /usr/bin/awk -v label="$2" -v code="$3" '
        index($0, label) && $NF == code { found=1 }
        END { exit(found ? 0 : 1) }
    '
}

expect_failure() {
    "$@" >/dev/null 2>&1
    [ "$?" -ne 0 ]
}

test_status_sources() {
    new_case
    local output
    output="$(ctl status)" || return 1
    assert_source_line "$output" "Location / 定位" "CN" || return 1
    assert_source_line "$output" "GeoIP" "CA" || return 1
    assert_source_line "$output" "Wi-Fi" "CN" || return 1
    assert_source_line "$output" "Combined / 综合" "CA" || return 1
    assert_source_line "$output" "All referenced / 全部引用" "CN,CA" || return 1
}

test_precise_set_and_lock() {
    new_case
    ctl set US >/dev/null || return 1
    /usr/bin/chflags -R nouchg "$STATE" 2>/dev/null || true
    [ "$(/usr/bin/plutil -extract '$objects.4' raw "$TARGET")" = "US" ] || return 1
    [ "$(/usr/bin/plutil -extract '$objects.8' raw "$TARGET")" = "US" ] || return 1
    [ "$(/usr/bin/plutil -extract '$objects.12' raw "$TARGET")" = "US" ] || return 1
    [ "$(/usr/bin/plutil -extract '$objects.16' raw "$TARGET")" = "US" ] || return 1
    [ "$(/usr/bin/plutil -extract '$objects.20' raw "$TARGET")" = "US" ] || return 1
    [ "$(/usr/bin/plutil -extract '$objects.5' raw "$TARGET")" = "ZZ" ] || return 1
    [ "$(/usr/bin/plutil -extract '$objects.13' raw "$TARGET")" = "DO-NOT-CHANGE" ] || return 1
    /usr/bin/stat -f '%Sf' "$TARGET" | /usr/bin/grep -q uchg || return 1
}

test_backup_is_first_original() {
    new_case
    local first_hash second_hash
    ctl set US >/dev/null || return 1
    first_hash="$(/usr/bin/shasum -a 256 "$STATE/original.plist" | /usr/bin/awk '{print $1}')"
    ctl set CA >/dev/null || return 1
    second_hash="$(/usr/bin/shasum -a 256 "$STATE/original.plist" | /usr/bin/awk '{print $1}')"
    [ "$first_hash" = "$second_hash" ] || return 1
    /usr/bin/chflags nouchg "$TARGET"
    /usr/bin/cmp -s "$STATE/original.plist" "$ORIGINAL_COPY" || return 1
}

test_unlock_and_restore() {
    new_case
    ctl set JP >/dev/null || return 1
    ctl unlock >/dev/null || return 1
    ! /usr/bin/stat -f '%Sf' "$TARGET" | /usr/bin/grep -q uchg || return 1
    ctl set SG >/dev/null || return 1
    /usr/bin/chflags nouchg "$TARGET" || return 1
    /bin/chmod u+w "$TARGET" || return 1
    printf 'damaged cache\n' > "$TARGET"
    ctl restore >/dev/null || return 1
    /usr/bin/cmp -s "$TARGET" "$ORIGINAL_COPY" || return 1
    ! /usr/bin/stat -f '%Sf' "$TARGET" | /usr/bin/grep -q uchg || return 1
}

test_invalid_country() {
    new_case
    expect_failure ctl set DE || return 1
    [ ! -e "$STATE" ] || return 1
    /usr/bin/cmp -s "$TARGET" "$ORIGINAL_COPY"
}

test_damaged_and_unknown_archives() {
    local source_xml unknown_xml
    new_case
    printf 'not a plist\n' > "$TARGET"
    expect_failure ctl set US || return 1
    new_case
    source_xml="$CASE_DIR/source.xml"
    unknown_xml="$CASE_DIR/unknown.xml"
    /usr/bin/plutil -convert xml1 -o "$source_xml" "$TARGET" >/dev/null || return 1
    /usr/bin/awk '
        /<key>CountryCode<\/key>/ { skipping=1; next }
        skipping {
            opens=gsub(/<dict>/, "&")
            closes=gsub(/<\/dict>/, "&")
            depth += opens - closes
            if (depth == 0 && closes > 0) skipping=0
            next
        }
        { print }
    ' "$source_xml" > "$unknown_xml" || return 1
    /bin/mv "$unknown_xml" "$TARGET" || return 1
    /usr/bin/plutil -lint "$TARGET" >/dev/null || return 1
    expect_failure ctl set US
}

test_missing_cache() {
    new_case
    /bin/rm "$TARGET"
    expect_failure ctl set US
}

test_external_lock_is_refused() {
    new_case
    /usr/bin/chflags uchg "$TARGET" || return 1
    expect_failure ctl set US || return 1
    /usr/bin/chflags nouchg "$TARGET"
    [ ! -e "$STATE" ]
}

test_platform_guards() {
    new_case
    TEST_OS_VERSION=26.0 expect_failure ctl set US || return 1
    TEST_OS_VERSION=27.0 TEST_ARCH=x86_64 expect_failure ctl set US || return 1
    TEST_ARCH=arm64 TEST_REGION=CH/A expect_failure ctl set US
}

test_test_mode_path_guard() {
    expect_failure env \
      ENABLE_MAC_SIRI_AI_TEST_MODE=1 \
      ENABLE_MAC_SIRI_AI_TARGET="$FIXTURE" \
      ENABLE_MAC_SIRI_AI_STATE_DIR="/tmp/enableMacSiriAI-safe-state" \
      "$ROOT/enableMacSiriAI" status
}

test_symlink_and_invalid_state_are_refused() {
    new_case
    /bin/mv "$TARGET" "$CASE_DIR/real-cache.plist"
    /bin/ln -s "$CASE_DIR/real-cache.plist" "$TARGET"
    expect_failure ctl set US || return 1
    new_case
    /bin/mkdir -m 700 "$STATE"
    printf 'invalid\n' > "$STATE/metadata"
    /bin/cp "$FIXTURE" "$STATE/original.plist"
    /bin/chmod 400 "$STATE/metadata" "$STATE/original.plist"
    expect_failure ctl set US || return 1
    /usr/bin/cmp -s "$TARGET" "$ORIGINAL_COPY"
}

test_interactive_action_returns_to_menu() {
    new_case
    local output menu_count
    output="$(printf '1\n0\n' | ctl)" || return 1
    menu_count="$(printf '%s\n' "$output" | /usr/bin/grep -c 'Actions / 操作:')"
    [ "$menu_count" -ge 2 ] || return 1
    [ "$(/usr/bin/plutil -extract '$objects.4' raw "$TARGET")" = "US" ] || return 1
    /usr/bin/stat -f '%Sf' "$TARGET" | /usr/bin/grep -q uchg
}

test_interactive_restore_accepts_lowercase() {
    new_case
    ctl set CA >/dev/null || return 1
    printf '5\nrestore\nn\n0\n' | ctl >/dev/null || return 1
    /usr/bin/cmp -s "$TARGET" "$ORIGINAL_COPY" || return 1
    [ -d "$STATE" ] || return 1
    ! /usr/bin/stat -f '%Sf' "$TARGET" | /usr/bin/grep -q uchg
}

test_restore_delete_and_recreate_backup() {
    new_case
    ctl set CA >/dev/null || return 1
    ctl restore --delete-backup >/dev/null || return 1
    /usr/bin/cmp -s "$TARGET" "$ORIGINAL_COPY" || return 1
    [ ! -e "$STATE" ] || return 1

    ctl set US >/dev/null || return 1
    [ -f "$STATE/original.plist" ] || return 1
    /usr/bin/cmp -s "$STATE/original.plist" "$ORIGINAL_COPY" || return 1
    expect_failure ctl restore --unknown
}

test_interactive_restore_can_delete_backup() {
    new_case
    ctl set CA >/dev/null || return 1
    printf '5\nRESTORE\ny\n0\n' | ctl >/dev/null || return 1
    /usr/bin/cmp -s "$TARGET" "$ORIGINAL_COPY" || return 1
    [ ! -e "$STATE" ]
}

test_legacy_backup_is_migrated() {
    new_case
    ctl set CA >/dev/null || return 1
    /bin/mv "$STATE" "$LEGACY_STATE" || return 1
    ctl set US >/dev/null || return 1
    [ -d "$STATE" ] || return 1
    [ ! -e "$LEGACY_STATE" ] || return 1
    [ -f "$STATE/original.plist" ]
}

run_test() {
    local name="$1"
    if "$name"; then pass "$name"; else fail "$name"; fi
}

run_test test_status_sources
run_test test_precise_set_and_lock
run_test test_backup_is_first_original
run_test test_unlock_and_restore
run_test test_invalid_country
run_test test_damaged_and_unknown_archives
run_test test_missing_cache
run_test test_external_lock_is_refused
run_test test_platform_guards
run_test test_test_mode_path_guard
run_test test_symlink_and_invalid_state_are_refused
run_test test_interactive_action_returns_to_menu
run_test test_interactive_restore_accepts_lowercase
run_test test_restore_delete_and_recreate_backup
run_test test_interactive_restore_can_delete_backup
run_test test_legacy_backup_is_migrated

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
