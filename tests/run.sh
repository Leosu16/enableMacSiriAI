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
      ENABLE_MAC_SIRI_AI_TEST_ROUTE_RESULTS="${TEST_ROUTE_RESULTS:-}" \
      ENABLE_MAC_SIRI_AI_SKIP_SUDO=1 \
      ENABLE_MAC_SIRI_AI_SKIP_REFRESH=1 \
      "$ROOT/enableMacSiriAI" "$@"
}

pass() { PASS=$((PASS + 1)); printf 'ok %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'not ok %s\n' "$1" >&2; }

assert_contains() {
    case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

expect_failure() {
    "$@" >/dev/null 2>&1
    [ "$?" -ne 0 ]
}

test_status_sources() {
    new_case
    local output
    output="$(ctl status)" || return 1
    assert_contains "$output" "Location / 定位        CN" || return 1
    assert_contains "$output" "GeoIP                    CA" || return 1
    assert_contains "$output" "Wi-Fi                    CN" || return 1
    assert_contains "$output" "Combined / 综合        CA" || return 1
    assert_contains "$output" "All referenced / 全部引用 CN,CA" || return 1
}

test_diagnose_is_read_only_and_complete() {
    new_case
    local before output after
    before="$(/usr/bin/shasum -a 256 "$TARGET" | /usr/bin/awk '{print $1}')"
    output="$(ctl diagnose)" || return 1
    after="$(/usr/bin/shasum -a 256 "$TARGET" | /usr/bin/awk '{print $1}')"
    [ "$before" = "$after" ] || return 1
    [ ! -e "$STATE" ] || return 1
    assert_contains "$output" "GREYMATTER answer:                    4" || return 1
    assert_contains "$output" "COUNTRY_LOCATION" || return 1
    assert_contains "$output" "DEVICE_AND_SIRI_LANGUAGE_MATCH" || return 1
    assert_contains "$output" "FOUNDATION_MODELS answer:             4" || return 1
    assert_contains "$output" "ChatGPT extension / ChatGPT 扩展:     true" || return 1
    assert_contains "$output" "CountryCode/locale match / 地区匹配:" || return 1
}

test_diagnose_recognizes_completed_setup() {
    new_case
    ctl set CA >/dev/null || return 1
    local output
    output="$(ctl diagnose)" || return 1
    assert_contains "$output" "Country-code setup is complete" || return 1
    assert_contains "$output" "如果 Siri AI 仍不可用，请按上方联网建议处理"
}

test_diagnose_audits_complete_siri_routes() {
    new_case
    local output
    TEST_ROUTE_RESULTS="$ROOT/tests/fixtures/routes-complete.tsv" output="$(ctl diagnose)" || return 1
    assert_contains "$output" "No Siri AI domain connected to a China endpoint" || return 1
    ! assert_contains "$output" "api-siri-prod.apple.com" || return 1
    ! assert_contains "$output" "uschi7.icloud-content.com" || return 1
    ! assert_contains "$output" "LEAK / 疑似漏代理"
}

test_diagnose_reports_leaking_siri_routes() {
    new_case
    ctl set CA >/dev/null || return 1
    local output
    TEST_ROUTE_RESULTS="$ROOT/tests/fixtures/routes-leaking.tsv" output="$(ctl diagnose 2>&1)" || return 1
    ! assert_contains "$output" "probe.icloud.com" || return 1
    ! assert_contains "$output" "api-siri-prod.apple.com" || return 1
    ! assert_contains "$output" "UNKNOWN / 无法判定" || return 1
    ! assert_contains "$output" "uschi7.icloud-content.com" || return 1
    ! assert_contains "$output" "LEAK / 疑似漏代理" || return 1
    assert_contains "$output" "Siri AI may not be able to access the network normally" || return 1
    assert_contains "$output" "enable global proxy and TUN mode" || return 1
    assert_contains "$output" "raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_Clash.yaml" || return 1
    assert_contains "$output" "place RULE-SET first" || return 1
    assert_contains "$output" "raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_ChatGPT.lpx" || return 1
    assert_contains "$output" "raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_ChatGPT.srmodule" || return 1
}

test_modules_include_date_and_minimum_system_without_system_or_version() {
    local module
    for module in "$ROOT/Siri_AI_ChatGPT.lpx" "$ROOT/Siri_AI_ChatGPT.srmodule"; do
        /usr/bin/grep -Eq '^#!date ?= ?2026-08-13 00:42 UTC\+8$' "$module" || return 1
        /usr/bin/grep -Eq '^#!system_version ?= ?27$' "$module" || return 1
        if /usr/bin/grep -Eq '^#!system ?=' "$module"; then
            return 1
        fi
        if /usr/bin/grep -Fq '最后更新时间' "$module"; then
            return 1
        fi
        if /usr/bin/grep -Eq '版本 0\.[0-9]+\.[0-9]+' "$module"; then
            return 1
        fi
        if /usr/bin/grep -Fq 'PROCESS-NAME,assistantd,PROXY' "$module"; then
            return 1
        fi
    done
}

test_clash_ruleset_is_classical_and_includes_assistantd() {
    local ruleset="$ROOT/Siri_AI_Clash.yaml"
    /usr/bin/grep -Fq 'payload:' "$ruleset" || return 1
    /usr/bin/grep -Fq 'PROCESS-NAME,assistantd' "$ruleset" || return 1
    /usr/bin/grep -Fq 'DOMAIN-SUFFIX,pcc.apple.com' "$ruleset" || return 1
    /usr/bin/grep -Fq 'Version 0.2.0 · Updated 2026-08-13 00:42 (UTC+8)' "$ruleset" || return 1
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
    new_case
    printf 'not a plist\n' > "$TARGET"
    expect_failure ctl set US || return 1
    new_case
    /usr/bin/plutil -remove '$objects.3.CountryCode' "$TARGET" >/dev/null
    /usr/bin/plutil -remove '$objects.7.CountryCode' "$TARGET" >/dev/null
    /usr/bin/plutil -remove '$objects.11.CountryCode' "$TARGET" >/dev/null
    /usr/bin/plutil -remove '$objects.15.CountryCode' "$TARGET" >/dev/null
    /usr/bin/plutil -remove '$objects.19.CountryCode' "$TARGET" >/dev/null
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
run_test test_diagnose_is_read_only_and_complete
run_test test_diagnose_recognizes_completed_setup
run_test test_diagnose_audits_complete_siri_routes
run_test test_diagnose_reports_leaking_siri_routes
run_test test_modules_include_date_and_minimum_system_without_system_or_version
run_test test_clash_ruleset_is_classical_and_includes_assistantd
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
