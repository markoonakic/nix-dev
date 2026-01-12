# Nix Dev Init

One-command project initialization with **direnv** (local, fast) and/or **container** (portable, isolated) workflows powered by Nix.

## Features

- ✅ **Two workflows in one** - Direnv for local Mac, containers for remote servers
- ✅ **Minimal containers** - ~300MB (vs Microsoft devcontainer 1.05GB)
- ✅ **No bloat** - Only downloads files you actually need
- ✅ **Interactive & safe** - Preview changes, conflict resolution
- ✅ **Idempotent** - Safe to run multiple times
- ✅ **Add workflows later** - Start with direnv, add container anytime
- ✅ **Your dotfiles inside** - Containers include your nix-dotfiles config

## Quick Start

### Initialize New Project

```bash
# In any project directory
curl -fsSL https://raw.githubusercontent.com/markoonakic/nix-dev/main/init.sh | bash
```

The script will ask you to:
1. Choose a template (python-uv, shell, or base)
2. Choose a workflow (direnv only, container only, or both)
3. Preview changes before creating files
4. Handle any conflicts interactively

### Available Templates

| Template | Description | Includes |
|----------|-------------|----------|
| **python-uv** | Python with uv package manager | Python 3.11, uv, git, pyproject.toml |
| **shell** | Shell/DevOps tools | kubectl, jq, yq, shellcheck, bash |
| **base** | Minimal base template | Just git |

## Workflows

### Direnv Workflow (Local Development)

**Use when:** Working on your Mac, want instant environment activation

```bash
# Initialize with direnv
curl -fsSL ... | bash
# Select: python-uv
# Select: Direnv only

# Trust the environment
direnv allow

# Now cd into the directory auto-activates the environment
cd my-project  # Python 3.11 + uv available
cd ..          # Environment unloaded
```

**Files created:**
- `flake.nix` - Nix development environment
- `.envrc` - direnv configuration

### Container Workflow (Remote/Isolated)

**Use when:** Working on remote servers, need full isolation, or testing on Linux

```bash
# Initialize with container
curl -fsSL ... | bash
# Select: python-uv
# Select: Container only

# Start container
devpod up .

# SSH into container
devpod ssh .
```

**Files created:**
- `flake.nix` - Nix development environment (used inside container)
- `devcontainer/Dockerfile` - Minimal Debian + Nix + your dotfiles
- `devcontainer/devcontainer.json` - DevPod configuration

**Container includes:**
- Debian stable-slim base (27MB)
- Nix package manager (~100MB)
- Your nix-dotfiles (same shell, aliases, tools as your Mac)
- Total: ~300MB (vs Microsoft devcontainer 1.05GB)

### Both Workflows (Recommended)

**Use when:** Want local speed + remote portability

```bash
# Initialize with both
curl -fsSL ... | bash
# Select: python-uv
# Select: Both

# Use direnv locally on Mac
direnv allow

# Use container on remote server
git push
# On server:
devpod up .
```

**Files created:** All files from both workflows

## Adding Workflows Later

### Add Container to Existing Direnv Project

```bash
curl -fsSL https://raw.githubusercontent.com/markoonakic/nix-dev/main/init.sh | bash -s -- --add-container
```

Only adds `devcontainer/` files, doesn't touch `flake.nix` or `.envrc`.

### Add Direnv to Existing Container Project

```bash
curl -fsSL https://raw.githubusercontent.com/markoonakic/nix-dev/main/init.sh | bash -s -- --add-direnv
```

Only adds `.envrc`, uses existing `flake.nix`.

## Non-Interactive Usage

```bash
# Specify options directly
curl -fsSL ... | bash -s -- --template python-uv --workflow both

# Force overwrite existing files
curl -fsSL ... | bash -s -- --template shell --workflow direnv --force
```

## How It Works

### Direnv Workflow

1. `flake.nix` defines your development environment (Python, Node, tools, etc.)
2. `.envrc` tells direnv to load the Nix environment
3. When you `cd` into the directory, direnv runs `nix develop` automatically
4. Tools from `flake.nix` become available in your shell
5. When you `cd` out, the environment unloads

### Container Workflow

1. `Dockerfile` builds from Debian stable-slim + Nix
2. Installs Nix inside the container
3. Clones your [nix-dotfiles](https://github.com/markoonakic/nix-dotfiles) and applies Home Manager
4. Now you have the same shell, aliases, and tools as your Mac inside the container
5. `flake.nix` provides project-specific tools (Python, Node, etc.)
6. `devcontainer.json` configures DevPod

## Container Size Comparison

| Image | Size | Contents |
|-------|------|----------|
| **Microsoft devcontainer** | 1.05GB | 253 packages, user "vscode" |
| **nix-dev** | ~300MB | Debian stable-slim + Nix + your dotfiles, user "marko" |
| **Savings** | **71%** | 750MB less |

## Conflict Resolution

When running the script on an existing project, you'll get interactive prompts:

```
⚠️  flake.nix already exists

What should I do?
  1) Keep existing (skip)
  2) Overwrite
  3) Backup as flake.nix.backup
  4) Show diff
  5) Abort

Choice [1]:
```

Safe and transparent - you're always in control.

## Examples

### Example 1: New Python Project (Both Workflows)

```bash
mkdir my-python-app && cd my-python-app

# Initialize
curl -fsSL https://raw.githubusercontent.com/markoonakic/nix-dev/main/init.sh | bash
# Select: 1 (python-uv)
# Select: 3 (both)

# Use direnv locally
direnv allow
python --version  # Python 3.11
uv --version      # uv available

# Push to GitHub
git init && git add . && git commit -m "init" && git push

# Use container on remote server
ssh server
git clone my-repo && cd my-repo
devpod up .
devpod ssh .
# Same environment as your Mac!
```

### Example 2: Shell Scripts Project (Direnv Only)

```bash
mkdir shell-scripts && cd shell-scripts

curl -fsSL ... | bash
# Select: 2 (shell)
# Select: 1 (direnv only)

direnv allow

# Now kubectl, jq, yq, shellcheck available
kubectl version
jq --version
```

### Example 3: Add Container Later

```bash
# Started with direnv, now need container for testing on Linux
curl -fsSL ... | bash -s -- --add-container

# Container files added, direnv files unchanged
devpod up .
```

## Integration with nix-dotfiles

Containers automatically include your personal environment:

1. Dockerfile clones [nix-dotfiles](https://github.com/markoonakic/nix-dotfiles)
2. Runs `home-manager switch --flake .#marko@devcontainer`
3. You get your zsh config, aliases, tools inside the container
4. Feels like home, even on remote servers

If you don't have nix-dotfiles yet, the container will use a minimal default environment.

## Requirements

### For Direnv Workflow
- Nix with flakes enabled
- direnv installed

### For Container Workflow
- Docker or compatible container runtime
- DevPod (or Docker/Podman directly)

## Troubleshooting

### Direnv: "nix: command not found"

```bash
# Install Nix first
curl -L https://nixos.org/nix/install | sh

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Direnv: ".envrc is blocked"

```bash
direnv allow
```

### Container: Build fails to clone nix-dotfiles

If you haven't created nix-dotfiles yet, edit `Dockerfile` and remove the Home Manager section. The container will work with a basic shell.

## Customization

### Modify flake.nix

Add/remove tools in your `flake.nix`:

```nix
buildInputs = with pkgs; [
  python311
  uv
  # Add more tools
  nodejs
  terraform
];
```

Run `direnv reload` or rebuild the container to apply changes.

### Change Container User

Edit `devcontainer/Dockerfile`:

```dockerfile
ARG USERNAME=yourname  # Change from marko
```

## Learn More

- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [direnv](https://direnv.net/)
- [DevPod](https://devpod.sh/)
- [Home Manager](https://github.com/nix-community/home-manager)
- [nix-dotfiles](https://github.com/markoonakic/nix-dotfiles)

## License

MIT
