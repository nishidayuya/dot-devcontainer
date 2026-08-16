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

# Install Claude Desktop from Anthropic's apt repository
# (https://code.claude.com/docs/en/desktop-linux). It is an Electron
# application and draws on the host's Wayland compositor through the socket
# that devcontainer.json bind-mounts.
#
# --no-install-recommends keeps qemu-system-x86, ovmf and virtiofsd out of the
# image: they are only used by Cowork's virtual machine sandbox and would add
# more than a gigabyte. The packages listed next to claude-desktop are chosen
# by hand instead:
#   - libglib2.0-bin satisfies the "kde-cli-tools | ... | libglib2.0-bin |
#     gvfs" dependency with gio, so that apt does not pull in KDE for its first
#     alternative.
#   - libasound2t64 and libayatana-appindicator3-1 are recommendations worth
#     keeping: sound playback and the tray icon.
RUN curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc \
      https://downloads.claude.ai/claude-desktop/key.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
      > /etc/apt/sources.list.d/claude-desktop.list \
    && apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    claude-desktop \
    libglib2.0-bin \
    libasound2t64 \
    libayatana-appindicator3-1

# Puts claude-desktop on Wayland; see the comments in the script itself
COPY --chmod=0755 claude-desktop-wrapper.sh /usr/local/bin/claude-desktop

USER vscode
ENV MISE_DATA_DIR=/home/vscode/.local/share/mise
ENV MISE_CONFIG_DIR=/home/vscode/.config/mise
ENV PATH="/home/vscode/.local/bin:/home/vscode/.devcontainers/bin:/home/vscode/.local/share/mise/shims:${PATH}"

# DevPod reports anonymous usage statistics unless told not to. The firewall
# blocks that endpoint anyway, so turn it off rather than have every invocation
# wait on a rejected connection.
ENV DEVPOD_DISABLE_TELEMETRY=true

# Install tools
# Dev Container CLI is installed with the standalone script, which bundles its
# own Node.js runtime (https://github.com/devcontainers/cli#install-script)
RUN curl -fsSL https://raw.githubusercontent.com/devcontainers/cli/main/scripts/install.sh | sh
# DevPod CLI runs the same devcontainer.json on a pluggable backend. It ships as
# a single static binary (https://devpod.sh/docs/getting-started/install), and
# the built-in "docker" provider is registered here so that it targets the local
# Docker daemon provided by the docker-in-docker feature. That provider is
# embedded in the binary, so adding it needs no network access.
#
# Git credential and ssh signature forwarding are turned off because both work
# by rewriting ~/.gitconfig inside the workspace. Here that file is a symlink
# into /dev_container_home (see post_start_command.d/10-dev-container-home), so
# DevPod would edit the shared configuration on the host and leave behind a
# credential helper and a gpg.ssh.program pointing at paths that only exist
# inside the workspace, breaking git outside of it.
#
# The default IDE is set to "none" because DevPod otherwise falls back to
# opening VS Code, and there is none to open in here. "devpod up" then just
# starts the workspace, and "devpod ssh" is how you enter it.
#
# The binary is downloaded straight to its final location: DevPod itself uses
# /tmp/devpod as a working directory, so staging the download there would make
# every later "mkdir /tmp/devpod" fail with "not a directory".
RUN arch="$(dpkg --print-architecture)" \
    && install -d -m 0755 /home/vscode/.local/bin \
    && curl -fsSL -o /home/vscode/.local/bin/devpod \
      "https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-${arch}" \
    && chmod 0755 /home/vscode/.local/bin/devpod \
    && devpod provider add docker \
    && devpod context set-options \
      -o SSH_INJECT_GIT_CREDENTIALS=false \
      -o GIT_SSH_SIGNATURE_FORWARDING=false \
    && devpod ide use none
# Install Claude Code via the native installer (https://code.claude.com/docs/ja/quickstart)
RUN curl -fsSL https://claude.ai/install.sh | bash
# Antigravity CLI is distributed as a native binary (installed to ~/.local/bin/agy), not via npm
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash
RUN mise use -g ruby@latest
# Node.js is not required anymore: the Dev Container CLI standalone installer
# bundles its own runtime. Uncomment if your project needs Node.js and npm.
# RUN mise use -g node@24
# Rust is not installed by default. Uncomment if your project needs rustc and
# cargo. mise installs and drives rustup under the hood.
# RUN mise use -g rust@latest
# Git is already provided by apt above. Uncomment to manage a newer Git with
# mise instead, using the asdf-git plugin
# (https://github.com/nishidayuya/asdf-git). It builds Git from source, so the
# first RUN below installs Git's extra build dependencies. Git 2.55 and later
# also build Rust code (libgitcore) unless NO_RUST is set, so the rust line
# above has to be uncommented too.
# RUN sudo apt-get update \
#     && sudo env -- DEBIAN_FRONTEND=noninteractive \
#     apt-get -y install --no-install-recommends \
#     gettext \
#     libcurl4-openssl-dev \
#     libexpat1-dev
# RUN mise plugin add git https://github.com/nishidayuya/asdf-git \
#     && mise use -g git@latest

# Setup shell for mise
RUN echo 'eval "$(mise activate bash)"' >> ~/.bashrc \
    && echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
