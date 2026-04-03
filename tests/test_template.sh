#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "$0")/../template" && pwd)"
PASS=0
FAIL=0
FAILURES=""

# --- Helpers ---

generate() {
    local dest="$1"
    local name="${2:-test-app}"
    shift 2 || shift 1
    local defines=(
        --define "description=A test application"
        --define "github_username=TestUser"
        --define "open_source=true"
        --define "publish_to_crates_io=false"
    )
    # Override defaults with any extra --define args
    for arg in "$@"; do
        defines+=("--define" "$arg")
    done
    cargo generate --path "$TEMPLATE_DIR" --name "$name" --destination "$dest" "${defines[@]}" 2>&1
}

assert_file_exists() {
    if [[ ! -f "$1" ]]; then
        echo "  FAIL: expected file $1 to exist"
        return 1
    fi
}

assert_file_not_exists() {
    if [[ -f "$1" ]]; then
        echo "  FAIL: expected file $1 to NOT exist"
        return 1
    fi
}

assert_dir_not_exists() {
    if [[ -d "$1" ]]; then
        echo "  FAIL: expected directory $1 to NOT exist"
        return 1
    fi
}

assert_contains() {
    local file="$1" pattern="$2"
    if ! grep -q "$pattern" "$file"; then
        echo "  FAIL: expected '$pattern' in $file"
        return 1
    fi
}

assert_not_contains() {
    local file="$1" pattern="$2"
    if grep -q "$pattern" "$file"; then
        echo "  FAIL: expected '$pattern' to NOT be in $file"
        return 1
    fi
}

run_test() {
    local name="$1"
    shift
    echo -n "  $name ... "
    if "$@"; then
        echo "ok"
        PASS=$((PASS + 1))
    else
        echo "FAILED"
        FAIL=$((FAIL + 1))
        FAILURES="${FAILURES}\n  $name"
    fi
}

# --- Template structure tests ---

test_generates_all_expected_files() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" > /dev/null

    local p="$tmp/test-app"
    assert_file_exists "$p/Cargo.toml" &&
    assert_file_exists "$p/src/main.rs" &&
    assert_file_exists "$p/README.md" &&
    assert_file_exists "$p/CLAUDE.md" &&
    assert_file_exists "$p/AGENTS.md" &&
    assert_file_exists "$p/deny.toml" &&
    assert_file_exists "$p/.gitignore" &&
    assert_file_exists "$p/.github/workflows/ci.yml" &&
    assert_file_exists "$p/.github/workflows/claude.yml" &&
    assert_file_exists "$p/.github/dependabot.yml"
}

test_excludes_template_infrastructure() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" > /dev/null

    local p="$tmp/test-app"
    assert_dir_not_exists "$p/tests" &&
    assert_file_not_exists "$p/cargo-generate.toml" &&
    assert_file_not_exists "$p/.github/workflows/template-ci.yml"
}

# --- Conditional: open_source ---

test_open_source_includes_license() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" test-app "open_source=true" > /dev/null

    local p="$tmp/test-app"
    assert_file_exists "$p/LICENSE" &&
    assert_contains "$p/LICENSE" "MIT License" &&
    assert_contains "$p/Cargo.toml" 'license = "MIT"'
}

test_not_open_source_has_proprietary_license() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" test-app "open_source=false" > /dev/null

    local p="$tmp/test-app"
    assert_file_exists "$p/LICENSE" &&
    assert_contains "$p/LICENSE" "All rights reserved" &&
    assert_not_contains "$p/LICENSE" "MIT" &&
    assert_contains "$p/Cargo.toml" 'license-file = "LICENSE"'
}

# --- Conditional: publish_to_crates_io ---

test_publish_includes_workflow_and_badge() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" test-app "publish_to_crates_io=true" > /dev/null

    local p="$tmp/test-app"
    assert_file_exists "$p/.github/workflows/publish.yml" &&
    assert_contains "$p/README.md" "crates.io" &&
    assert_not_contains "$p/Cargo.toml" "publish = false"
}

test_no_publish_excludes_workflow() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" test-app "publish_to_crates_io=false" > /dev/null

    local p="$tmp/test-app"
    assert_file_not_exists "$p/.github/workflows/publish.yml" &&
    assert_contains "$p/Cargo.toml" "publish = false" &&
    assert_not_contains "$p/README.md" "crates.io"
}

# --- Variable substitution ---

test_project_name_substituted() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" my-cool-tool > /dev/null

    local p="$tmp/my-cool-tool"
    assert_contains "$p/Cargo.toml" 'name = "my-cool-tool"' &&
    assert_contains "$p/README.md" "# my-cool-tool"
}

test_description_substituted() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" test-app "description=A fancy CLI tool" > /dev/null

    assert_contains "$tmp/test-app/Cargo.toml" 'description = "A fancy CLI tool"'
}

test_github_username_substituted() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" test-app "github_username=octocat" > /dev/null

    local p="$tmp/test-app"
    assert_contains "$p/Cargo.toml" "github.com/octocat/" &&
    assert_contains "$p/README.md" "github.com/octocat/"
}

# --- Integration: build and run ---

test_generated_project_builds() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" > /dev/null

    cargo build --all-targets --manifest-path "$tmp/test-app/Cargo.toml" 2>&1
}

test_generated_project_tests_pass() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" > /dev/null

    cargo test --all-targets --manifest-path "$tmp/test-app/Cargo.toml" 2>&1
}

test_generated_project_formatting() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" > /dev/null

    cargo fmt --all --manifest-path "$tmp/test-app/Cargo.toml" -- --check 2>&1
}

test_generated_project_clippy() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" > /dev/null

    cargo clippy --all-targets --manifest-path "$tmp/test-app/Cargo.toml" -- -D warnings 2>&1
}

test_cli_runs_with_version() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" > /dev/null

    cargo build --manifest-path "$tmp/test-app/Cargo.toml" 2>/dev/null
    local output
    output="$(cargo run --manifest-path "$tmp/test-app/Cargo.toml" -- --version 2>&1)"
    echo "$output" | grep -q "test-app"
}

test_cli_runs_with_help() {
    local tmp
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    generate "$tmp" > /dev/null

    cargo build --manifest-path "$tmp/test-app/Cargo.toml" 2>/dev/null
    local output
    output="$(cargo run --manifest-path "$tmp/test-app/Cargo.toml" -- --help 2>&1)"
    echo "$output" | grep -q "A test application"
}

# --- Run all tests ---

echo "Template structure"
run_test "generates all expected files" test_generates_all_expected_files
run_test "excludes template infrastructure" test_excludes_template_infrastructure

echo "Conditional: open_source"
run_test "open_source=true includes LICENSE" test_open_source_includes_license
run_test "open_source=false has proprietary licence" test_not_open_source_has_proprietary_license

echo "Conditional: publish_to_crates_io"
run_test "publish=true includes workflow and badge" test_publish_includes_workflow_and_badge
run_test "publish=false excludes workflow" test_no_publish_excludes_workflow

echo "Variable substitution"
run_test "project name substituted" test_project_name_substituted
run_test "description substituted" test_description_substituted
run_test "github_username substituted" test_github_username_substituted

echo "Integration"
run_test "generated project builds" test_generated_project_builds
run_test "generated project tests pass" test_generated_project_tests_pass
run_test "generated project formatting" test_generated_project_formatting
run_test "generated project clippy" test_generated_project_clippy
run_test "CLI --version works" test_cli_runs_with_version
run_test "CLI --help works" test_cli_runs_with_help

# --- Summary ---

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
    echo -e "Failures:$FAILURES"
    exit 1
fi
