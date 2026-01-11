FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Minimal essentials (~20MB increase from base 78MB)
RUN apt-get update && apt-get install -y \
    bash \
    ca-certificates \
    curl \
    git \
    sudo \
    wget \
    xz-utils \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Create user (NOT "vscode")
ARG USERNAME=marko
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID $USERNAME 2>/dev/null || groupmod -n $USERNAME $(getent group $USER_GID | cut -d: -f1) \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/zsh 2>/dev/null || usermod -l $USERNAME -d /home/$USERNAME -m $(getent passwd $USER_UID | cut -d: -f1) \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USERNAME
ENV USER=$USERNAME
WORKDIR /home/$USERNAME

# Install Nix (~100MB)
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon && \
    echo '. ~/.nix-profile/etc/profile.d/nix.sh' >> ~/.zshrc && \
    mkdir -p ~/.config/nix && \
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Clone and apply personal dotfiles via Home Manager (~50MB)
# This gives you same shell config as your Mac inside the container
ENV PATH="/home/marko/.nix-profile/bin:${PATH}"

RUN \
    nix run nixpkgs#git -- clone --depth 1 https://github.com/markoonakic/nix-dotfiles.git ~/.config/nix-dotfiles && \
    ARCH=$(uname -m) && \
    nix run home-manager -- switch -b backup --flake ~/.config/nix-dotfiles#marko@devcontainer-${ARCH}

WORKDIR /workspace
CMD ["zsh"]
