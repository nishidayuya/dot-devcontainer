FROM mcr.microsoft.com/devcontainers/ruby:4.0-trixie

# Node.js のインストール (Gemini CLI のために必要)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs

# Gemini CLI のインストール
RUN npm install -g @google/gemini-cli

# Chromium と依存パッケージのインストール
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        chromium \
        curl \
        gnupg \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
