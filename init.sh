#!/usr/bin/env bash
set -euo pipefail

# Nix Development Environment Initializer
# Repository: https://github.com/markoonakic/nix-dev

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REPO_URL="https://raw.githubusercontent.com/markoonakic/nix-dev/main"
DRY_RUN=false
FORCE=false

# Available templates
declare -A TEMPLATES
TEMPLATES=(
    ["python-uv"]="Python with uv package manager"
    ["shell"]="Shell/DevOps tools"
    ["base"]="Minimal base template"
)

# Workflow modes
declare -A WORKFLOWS
WORKFLOWS=(
    ["direnv"]="Direnv only (fast, local development)"
    ["container"]="Container only (portable, isolated)"
    ["both"]="Both (direnv for local, container for remote)"
)

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Download a single file
download_file() {
    local url="$1"
    local dest="$2"
    local description="$3"

    # Handle conflict if file exists
    if [ -f "$dest" ] && ! $FORCE; then
        handle_conflict "$dest" "$url"
        return $?
    fi

    if $DRY_RUN; then
        echo -e "  ${GREEN}CREATE:${NC} $dest ($description)"
        return 0
    fi

    # Create parent directory
    mkdir -p "$(dirname "$dest")"

    # Download file
    if curl -fsSL "$url" -o "$dest"; then
        success "Created $dest"
        return 0
    else
        error "Failed to download $dest"
        return 1
    fi
}

# Handle file conflicts
handle_conflict() {
    local dest="$1"
    local url="$2"

    echo ""
    warn "$dest already exists"
    echo ""
    echo "What should I do?"
    echo "  1) Keep existing (skip)"
    echo "  2) Overwrite"
    echo "  3) Backup as ${dest}.backup"
    echo "  4) Show diff"
    echo "  5) Abort"
    echo ""
    # Read from /dev/tty to work even when script is piped
    echo -n "Choice [1]: "
    read choice </dev/tty 2>/dev/null || choice=""
    choice=${choice:-1}

    case "$choice" in
        1)
            info "Keeping existing file"
            return 0
            ;;
        2)
            info "Overwriting $dest"
            curl -fsSL "$url" -o "$dest"
            success "Overwrote $dest"
            return 0
            ;;
        3)
            info "Backing up to ${dest}.backup"
            cp "$dest" "${dest}.backup"
            curl -fsSL "$url" -o "$dest"
            success "Backed up and created $dest"
            return 0
            ;;
        4)
            # Download to temp and show diff
            local temp=$(mktemp)
            curl -fsSL "$url" -o "$temp"
            echo ""
            echo "Diff (< existing, > new):"
            diff "$dest" "$temp" || true
            echo ""
            rm "$temp"
            # Ask again
            handle_conflict "$dest" "$url"
            return $?
            ;;
        5)
            error "Aborted by user"
            exit 1
            ;;
        *)
            warn "Invalid choice, keeping existing file"
            return 0
            ;;
    esac
}

# Detect existing initialization
detect_existing() {
    local has_direnv=false
    local has_container=false

    [ -f "flake.nix" ] && has_direnv=true
    [ -f ".envrc" ] && has_direnv=true
    [ -f ".devcontainer/Dockerfile" ] && has_container=true

    if $has_direnv && $has_container; then
        echo "both"
    elif $has_direnv; then
        echo "direnv"
    elif $has_container; then
        echo "container"
    else
        echo "none"
    fi
}

# Interactive template selection
select_template() {
    echo "" >&2
    echo "Select template:" >&2
    local i=1
    local template_keys=()
    for key in "${!TEMPLATES[@]}"; do
        template_keys+=("$key")
    done

    # Sort for consistent order
    IFS=$'\n' sorted=($(sort <<<"${template_keys[*]}"))
    unset IFS

    for key in "${sorted[@]}"; do
        echo "  $i) $key - ${TEMPLATES[$key]}" >&2
        ((i++))
    done

    # Read from /dev/tty to work even when script is piped
    echo -n "Choice [1]: " >&2
    read choice </dev/tty 2>/dev/null || choice=""
    choice=${choice:-1}

    # Convert number to template name
    local selected="${sorted[$((choice-1))]}"
    echo "$selected"
}

# Interactive workflow selection
select_workflow() {
    echo "" >&2
    echo "Select workflow:" >&2
    echo "  1) Direnv only (fast, local development)" >&2
    echo "  2) Container only (portable, isolated)" >&2
    echo "  3) Both (direnv for local, container for remote)" >&2

    # Read from /dev/tty to work even when script is piped
    echo -n "Choice [3]: " >&2
    read choice </dev/tty 2>/dev/null || choice=""
    choice=${choice:-3}

    case "$choice" in
        1) echo "direnv" ;;
        2) echo "container" ;;
        3) echo "both" ;;
        *) echo "both" ;;
    esac
}

# Download template files
download_template() {
    local template="$1"
    local workflow="$2"
    local add_mode="$3"  # Optional: "add-container" or "add-direnv"
    local files=()

    # Common files (flake.nix)
    if [[ "$workflow" == "direnv" || "$workflow" == "both" ]]; then
        # Only add flake.nix if not in add-direnv mode (flake.nix should already exist)
        if [[ "$add_mode" != "direnv" ]]; then
            files+=("$REPO_URL/templates/$template/flake.nix|flake.nix|Nix development environment")
        fi
        files+=("$REPO_URL/templates/$template/.envrc|.envrc|direnv auto-activation")
    fi

    if [[ "$workflow" == "container" || "$workflow" == "both" ]]; then
        if [[ "$workflow" == "container" ]]; then
            # Container-only still needs flake.nix (used inside container)
            # But not if we're adding to existing direnv setup
            if [[ "$add_mode" != "container" ]]; then
                files+=("$REPO_URL/templates/$template/flake.nix|flake.nix|Nix development environment")
            fi
        fi
        files+=("$REPO_URL/templates/$template/.devcontainer/Dockerfile|.devcontainer/Dockerfile|Minimal Ubuntu + Nix")
        files+=("$REPO_URL/templates/$template/.devcontainer/devcontainer.json|.devcontainer/devcontainer.json|DevPod config")
    fi

    # Template-specific files (only during initial setup, not when adding workflows)
    if [[ -z "$add_mode" && "$template" == "python-uv" ]]; then
        files+=("$REPO_URL/templates/$template/pyproject.toml|pyproject.toml|Python project config")
    fi

    # Download all files
    for file_info in "${files[@]}"; do
        IFS='|' read -r url dest desc <<< "$file_info"
        download_file "$url" "$dest" "$desc" || return 1
    done

    return 0
}

# Preview changes
preview_changes() {
    local template="$1"
    local workflow="$2"
    local add_mode="$3"

    echo ""
    echo -e "${BLUE}📋 Preview of changes:${NC}"
    echo ""

    DRY_RUN=true
    download_template "$template" "$workflow" "$add_mode"
    DRY_RUN=false

    echo ""

    # Read from /dev/tty to work even when script is piped
    echo -n "Proceed with these changes? [Y/n]: "
    read proceed </dev/tty 2>/dev/null || proceed=""
    proceed=${proceed:-Y}

    if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
        info "Aborted by user"
        exit 0
    fi
}

# Main function
main() {
    local template=""
    local workflow=""
    local add_mode=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --template)
                template="$2"
                shift 2
                ;;
            --workflow)
                workflow="$2"
                shift 2
                ;;
            --add-container)
                add_mode="container"
                shift
                ;;
            --add-direnv)
                add_mode="direnv"
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    echo ""
    echo "🚀 Nix Development Environment Initializer"
    echo ""

    # Detect existing initialization
    local existing=$(detect_existing)

    if [[ "$existing" != "none" ]] && [[ -z "$add_mode" ]]; then
        warn "Existing initialization detected: $existing"
        echo ""
        echo "Options:"
        if [[ "$existing" == "direnv" ]]; then
            echo "  - Re-run with --add-container to add container workflow"
        elif [[ "$existing" == "container" ]]; then
            echo "  - Re-run with --add-direnv to add direnv workflow"
        else
            echo "  - Re-run with --force to overwrite existing files"
        fi
        echo "  - Or continue to update/modify existing setup"
        echo ""
        # Read from /dev/tty to work even when script is piped
        echo -n "Continue? [y/N]: "
        read continue </dev/tty 2>/dev/null || continue=""
        if [[ ! "$continue" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi

    # Handle add modes
    if [[ -n "$add_mode" ]]; then
        if [[ "$add_mode" == "container" && "$existing" == "container" ]]; then
            warn "Container workflow already exists"
            exit 0
        elif [[ "$add_mode" == "direnv" && "$existing" == "direnv" ]]; then
            warn "Direnv workflow already exists"
            exit 0
        fi

        workflow="$add_mode"

        # Try to detect template from existing flake.nix
        if [ -f "flake.nix" ]; then
            if grep -q "python" "flake.nix"; then
                template="python-uv"
            elif grep -q "kubectl" "flake.nix"; then
                template="shell"
            else
                template="base"
            fi
            info "Detected template: $template"
        else
            template=$(select_template)
        fi
    else
        # Interactive mode
        if [[ -z "$template" ]]; then
            template=$(select_template)
        fi

        if [[ -z "$workflow" ]]; then
            workflow=$(select_workflow)
        fi
    fi

    info "Template: $template"
    info "Workflow: $workflow"

    # Preview changes
    preview_changes "$template" "$workflow" "$add_mode"

    # Download files
    echo ""
    if download_template "$template" "$workflow" "$add_mode"; then
        echo ""
        success "✅ Initialization complete!"
        echo ""

        # Next steps
        echo "Next steps:"
        if [[ "$workflow" == "direnv" || "$workflow" == "both" ]]; then
            echo "  - For direnv: Run 'direnv allow' to trust .envrc"
        fi
        if [[ "$workflow" == "container" || "$workflow" == "both" ]]; then
            echo "  - For container: Run 'devpod up .' to start container"
        fi
        echo ""
    else
        error "Initialization failed"
        exit 1
    fi
}

# Run main
main "$@"
