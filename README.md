# dot-devcontainer

[![License X11](https://img.shields.io/badge/license-X11-blue.svg)](https://raw.githubusercontent.com/nishidayuya/dot-devcontainer/main/LICENSE.txt)
[![Latest tag](https://img.shields.io/github/v/tag/nishidayuya/dot-devcontainer)](https://github.com/nishidayuya/dot-devcontainer/tags)

A Dev Container configuration template pre-installed with `mise` and `Antigravity CLI`, featuring network access control (allowlist approach) via firewall.

## Features

- **Tool Management:** Manage Node.js, Ruby, and other tools using `mise`.
- **AI Integration:** Comes with `Antigravity CLI` (`agy`) pre-installed.
- **Security:** Outbound network traffic is restricted using `iptables` to only allow connections to specified hosts.
- **Extensibility:** Easily add allowed hosts by adding files to `.devcontainer/allow_hosts.d/`.
- **Independent home directory:** The directory pointed to by `DOT_DEVCONTAINER_HOME` on the host is mounted at `/dev_container_home`, and its entries are symlinked into the container home directory on start. Your real home directory is never mounted.

## Stack

- **OS:** Debian 13 (Bookworm)
- **Package Managers:** `apt`, `npm`, `gem`
- **Key Tools:**
  - `mise`
  - `gh` (GitHub CLI)
  - `docker-in-docker`
  - `Antigravity CLI`
  - `Chromium` & `Chromium Driver`

## Usage

### Install into an existing project

Run the following command in your project root to install the `.devcontainer` directory:

```sh
curl -f -sL https://raw.githubusercontent.com/nishidayuya/dot-devcontainer/main/install.sh | sh
```

For [`git-cococo`](https://github.com/nishidayuya/git-cococo) junkies:

```sh
DOT_DEVCONTAINER_REF="$(git ls-remote https://github.com/nishidayuya/dot-devcontainer.git refs/heads/main | awk '{print($1)}')" && git cococo sh -eux -c "curl -fsL https://github.com/nishidayuya/dot-devcontainer/raw/$DOT_DEVCONTAINER_REF/install.sh | DOT_DEVCONTAINER_REF=$DOT_DEVCONTAINER_REF sh"
```

### Preparing `DOT_DEVCONTAINER_HOME`

This Dev Container does not mount your host home directory. Instead, prepare a
separate directory that holds only the files you want to share with the
container, and point `DOT_DEVCONTAINER_HOME` at it:

```sh
mkdir -p ~/dev_container_home
export DOT_DEVCONTAINER_HOME="$HOME/dev_container_home"
```

Put the files and directories you want in the container home directory there:

```text
~/dev_container_home/
├── .claude/
├── .claude.json
├── .gemini/
└── .gitconfig
```

`DOT_DEVCONTAINER_HOME` must be visible to the process that launches the
container (e.g. set it in your shell profile before starting VS Code), because
it is resolved on the host.

### Starting the Dev Container

1. Open your project in VS Code.
2. Run the `Dev Containers: Reopen in Container` command.
3. `.devcontainer/setup-firewall.sh` will run automatically on start to apply the firewall rules.
4. `.devcontainer/setup-dev-container-home.sh` will run automatically on start to create symlinks in the container home directory (`/home/vscode`) for every entry directly under `/dev_container_home`. Entries with the same name in the home directory are replaced by the symlinks.
5. `.devcontainer/setup-known-hosts.sh` will run automatically on start to add GitHub's SSH host keys (fetched at startup via `ssh-keyscan`) to `~/.ssh/known_hosts`.

## Firewall Configuration

By default, traffic to major services like GitHub, RubyGems, npm, Google, and Microsoft is allowed.

To add allowed hosts, create a new file in `.devcontainer/allow_hosts.d/` and list domain names or IP addresses (one per line).

Example: `99-my-service`
```text
api.example.com
1.2.3.4
```

To apply changes inside the container, run:
```bash
sudo sh .devcontainer/setup-firewall.sh
```

## Prerequisites

- Docker Desktop or Docker Engine
- Visual Studio Code
- [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
- The container requires `NET_ADMIN` capability. It may not work in some restricted environments.

## License

See [LICENSE.txt](LICENSE.txt).
