#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install_root="${INSTALL_ROOT:-$project_root/third_party/install}"
overlay_root="$project_root/deploy/rootfs"
runtime_root="$overlay_root/opt/IoTEdge"
target_user="${TARGET_USER:-debian}"
repo_config_root="$project_root/config"
repo_service_root="$project_root/services"
repo_script_root="$project_root/deploy/scripts"
repo_app_root="$project_root/deploy/apps"
stage_only=false
clean_stage=false

usage() {
    cat <<USAGE
Usage: $(basename "$0") [--stage-only] [--clean] <target-ip-or-hostname>

Stages generated install artifacts into deploy/rootfs/opt/IoTEdge and syncs
the overlay to the target root filesystem.

Options:
  --stage-only  Build the host overlay without running rsync.
  --clean       Recreate deploy/rootfs before staging.
  --help        Show this help.

Environment:
  INSTALL_ROOT       Install tree to stage. Defaults to third_party/install.
  TARGET_USER        SSH user for the target. Defaults to "debian".

Examples:
  $(basename "$0") --stage-only
  $(basename "$0") --clean --stage-only
  TARGET_USER=debian $(basename "$0") 192.168.1.100
USAGE
}

log() {
    printf '[deploy] %s\n' "$*"
}

fail() {
    printf '[deploy] ERROR: %s\n' "$*" >&2
    exit 1
}

require_command() {
    local command_name=$1

    if ! command -v "$command_name" >/dev/null 2>&1; then
        fail "Required command '$command_name' was not found in PATH."
    fi
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --stage-only)
                stage_only=true
                ;;
            --clean)
                clean_stage=true
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            --*)
                usage >&2
                fail "Unknown option: $1"
                ;;
            *)
                if [ -n "${target:-}" ]; then
                    usage >&2
                    fail "Only one target may be provided."
                fi
                target=$1
                ;;
        esac
        shift
    done

    if [ "$stage_only" = false ] && [ -z "${target:-}" ]; then
        usage >&2
        fail "Target is required unless --stage-only is used."
    fi

    if [ "$stage_only" = true ] && [ -n "${target:-}" ]; then
        usage >&2
        fail "Do not pass a target with --stage-only."
    fi
}

require_install_tree() {
    if [ ! -d "$install_root" ]; then
        fail "Install root does not exist: $install_root"
    fi

    if ! find "$install_root" -mindepth 2 -type f -print -quit | grep -q .; then
        fail "Install root has no generated files: $install_root"
    fi
}

create_runtime_layout() {
    if [ "$clean_stage" = true ]; then
        log "Removing previous overlay: $overlay_root"
        rm -rf "$overlay_root"
    fi

    log "Creating runtime layout under deploy/rootfs/opt/IoTEdge."
    mkdir -p "$runtime_root/bin"
    mkdir -p "$runtime_root/config"
    mkdir -p "$runtime_root/data"
    mkdir -p "$runtime_root/lib"
    mkdir -p "$runtime_root/logs"
    mkdir -p "$runtime_root/scripts"
    mkdir -p "$runtime_root/services"
    mkdir -p "$runtime_root/apps"
    mkdir -p "$runtime_root/third_party"
}

copy_dir_contents() {
    local src=$1
    local dst=$2
    local label=$3

    if [ -d "$src" ]; then
        log "Staging $label: ${src#$project_root/} -> ${dst#$project_root/}"
        mkdir -p "$dst"
        cp -a "$src/." "$dst/"
    fi
}

stage_config_dir() {
    local package_dir=$1
    local package_name=$2
    local etc_dir="$package_dir/etc"
    local package_etc_dir="$etc_dir/$package_name"

    if [ ! -d "$etc_dir" ]; then
        return
    fi

    if [ -d "$package_etc_dir" ]; then
        copy_dir_contents "$package_etc_dir" \
            "$runtime_root/config/$package_name" \
            "$package_name configuration"
        return
    fi

    copy_dir_contents "$etc_dir" \
        "$runtime_root/config/$package_name" \
        "$package_name configuration"
}

stage_package() {
    local package_dir=$1
    local package_name
    package_name="$(basename "$package_dir")"

    log "Staging package: $package_name"

    copy_dir_contents "$package_dir" \
        "$runtime_root/third_party/$package_name" \
        "complete install tree for $package_name"

    copy_dir_contents "$package_dir/bin" \
        "$runtime_root/bin" \
        "$package_name binaries"

    copy_dir_contents "$package_dir/sbin" \
        "$runtime_root/bin" \
        "$package_name system binaries"

    copy_dir_contents "$package_dir/lib" \
        "$runtime_root/lib" \
        "$package_name libraries"

    stage_config_dir "$package_dir" "$package_name"

    copy_dir_contents "$package_dir/scripts" \
        "$runtime_root/scripts/$package_name" \
        "$package_name scripts"

    copy_dir_contents "$package_dir/services" \
        "$runtime_root/services/$package_name" \
        "$package_name services"
}

stage_install_tree() {
    local package_count=0
    local package_dir

    while IFS= read -r package_dir; do
        stage_package "$package_dir"
        package_count=$((package_count + 1))
    done < <(find "$install_root" -mindepth 1 -maxdepth 1 -type d | sort)

    if [ "$package_count" -eq 0 ]; then
        fail "No package install directories found under $install_root"
    fi

    log "Staged $package_count package install tree(s)."
}

stage_repo_runtime_files() {
    copy_dir_contents "$repo_app_root" \
        "$runtime_root/apps" \
        "repo-managed applications"

    copy_dir_contents "$repo_config_root" \
        "$runtime_root/config" \
        "repo-managed configuration"

    copy_dir_contents "$repo_service_root" \
        "$runtime_root/services" \
        "repo-managed services"

    copy_dir_contents "$repo_script_root" \
        "$runtime_root/scripts" \
        "target deployment scripts"

    find "$runtime_root" -name .gitkeep -type f -delete
}

print_layout() {
    log "Host deployment overlay:"
    find "$overlay_root" -mindepth 1 -print | sort
}

sync_overlay() {
    log "Syncing runtime root to target /opt/IoTEdge."
    log "Device requirement: /opt/IoTEdge must exist and be writable by $target_user."
    log "Device requirement: rsync must be installed on the target."

    if ! rsync -az --no-owner --no-group \
        "$runtime_root/" "${target_user}@${target}:/opt/IoTEdge/"; then
        fail "rsync failed. Create /opt/IoTEdge on the target and make it writable by $target_user."
    fi
}

target=""
parse_args "$@"

log "Project root: $project_root"
log "Install root: $install_root"

if [ "$stage_only" = true ]; then
    log "Mode: stage only"
else
    log "Target: ${target_user}@${target}"
    require_command rsync
fi

require_install_tree
create_runtime_layout
stage_install_tree
stage_repo_runtime_files
print_layout

if [ "$stage_only" = true ]; then
    log "Stage-only run complete."
    log "Overlay is ready at: $overlay_root"
    exit 0
fi

sync_overlay

log "Deployment complete."
log "Runtime root on target: /opt/IoTEdge"
log "Run these on the target:"
log "  /opt/IoTEdge/scripts/install-services.sh"
