FROM mcr.microsoft.com/devcontainers/base:debian-13

# Install git, gh, Chromium, and other dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    git \
    gh \
    openssh-client \
    iptables \
    curl \
    ca-certificates \
    gpg \
    gnupg \
    build-essential \
    libssl-dev \
    libyaml-dev \
    libreadline6-dev \
    zlib1g-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm6 \
    libgdbm-dev \
    dbus \
    kmod \
    chromium \
    chromium-driver \
    wget

# Install mise
RUN install -dm 755 /etc/apt/keyrings \
    && wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list \
    && apt-get update \
    && apt-get install -y mise

USER vscode
ENV MISE_DATA_DIR=/home/vscode/.local/share/mise
ENV MISE_CONFIG_DIR=/home/vscode/.config/mise
ENV PATH="/home/vscode/.local/bin:/home/vscode/.local/share/mise/shims:${PATH}"

# Install tools
RUN mise use -g node@24
RUN npm install -g @devcontainers/cli
# Install Claude Code via the native installer (https://code.claude.com/docs/ja/quickstart)
RUN curl -fsSL https://claude.ai/install.sh | bash
# Antigravity CLI is distributed as a native binary (installed to ~/.local/bin/agy), not via npm
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash
RUN mise use -g ruby@latest

# Setup shell for mise
RUN echo 'eval "$(mise activate bash)"' >> ~/.bashrc \
    && echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
