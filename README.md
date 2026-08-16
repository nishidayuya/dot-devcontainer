# dot-devcontainer

[![License X11](https://img.shields.io/badge/license-X11-blue.svg)](https://raw.githubusercontent.com/nishidayuya/dot-devcontainer/main/LICENSE.txt)
[![Latest tag](https://img.shields.io/github/v/tag/nishidayuya/dot-devcontainer)](https://github.com/nishidayuya/dot-devcontainer/tags)

A Dev Container configuration template pre-installed with `mise` and `Antigravity CLI`, featuring network access control (allowlist approach) via firewall.

## Features

- **Tool Management:** Manage Node.js, Ruby, and other tools using `mise`.
- **AI Integration:** Comes with `Antigravity CLI` (`agy`) pre-installed.
- **GUI applications:** `Claude Desktop` is pre-installed and draws on the Wayland compositor of the host, whose socket is bind-mounted into the container.
- **Nested dev containers:** Both the `Dev Container CLI` (`devcontainer`) and the `DevPod CLI` (`devpod`) are pre-installed, so a project's dev container can be built and started from inside this one.
- **Security:** Outbound network traffic is restricted using `iptables` to only allow connections to specified hosts.
- **Extensibility:** Easily add allowed hosts by adding files to `.devcontainer/allow_hosts.d/`.
- **Independent home directory:** The directory pointed to by `DOT_DEVCONTAINER_HOME` on the host is mounted at `/dev_container_home`, and its entries are symlinked into the container home directory on start. Your real home directory is never mounted.

## Stack

- **OS:** Debian 13 (Bookworm)
- **Package Managers:** `apt`, `gem` (`npm` and `cargo` are available once Node.js and Rust are enabled in the `Dockerfile`)
- **Key Tools:**
  - `mise`
  - `gh` (GitHub CLI)
  - `docker-in-docker`
  - `devcontainer` (Dev Container CLI)
  - `devpod` (DevPod CLI, with the built-in `docker` provider)
  - `Antigravity CLI`
  - `Claude Code` & `Claude Desktop`
  - `Chromium` & `Chromium Driver`

## Usage

### Install into an existing project

Run the following command in your project root to install the `.devcontainer` directory:

```sh
curl -f -sL https://raw.githubusercontent.com/nishidayuya/dot-devcontainer/main/install.sh | sh
```

To pin a specific version, set `DOT_DEVCONTAINER_REF` to a tag from the
[tag list](https://github.com/nishidayuya/dot-devcontainer/tags), and fetch
`install.sh` from that same ref so that the installer and the installed files
stay in sync:

```sh
DOT_DEVCONTAINER_REF=v4.0.0
curl -f -sL "https://raw.githubusercontent.com/nishidayuya/dot-devcontainer/$DOT_DEVCONTAINER_REF/install.sh" |
  DOT_DEVCONTAINER_REF="$DOT_DEVCONTAINER_REF" sh
```

`DOT_DEVCONTAINER_REF` accepts any Git ref — a tag, a branch name, or a commit
SHA. It defaults to `main`.

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
3. The scripts in `.devcontainer/post_start_command.d/` will run automatically on start, in filename order:
   - `00-firewall` applies the firewall rules.
   - `10-dev-container-home` creates symlinks in the container home directory (`/home/vscode`) for every entry directly under `/dev_container_home`. Entries with the same name in the home directory are replaced by the symlinks.
   - `20-known-hosts` adds GitHub's SSH host keys (fetched at startup via `ssh-keyscan`) to `~/.ssh/known_hosts`.
   - `30-claude-update` runs `claude update` to keep Claude Code on the latest version. Failures are ignored, so a network hiccup does not block startup.
   - `40-xdg-runtime-dir` gives `XDG_RUNTIME_DIR` (`/run/xdg_runtime_dir`, where the Wayland socket of the host is mounted) the ownership and the `0700` mode it is required to have.
   - `50-dbus-session` starts a session D-Bus daemon on `${XDG_RUNTIME_DIR}/bus`, which GUI applications need for `xdg-desktop-portal` file dialogs and for notifications.

The scripts in `.devcontainer/initialize_command.d/` run the same way, but on the **host** and before the container is created.

Both directories are driven by `.devcontainer/run-parts.sh`, a POSIX `sh`
reimplementation of `run-parts --exit-on-error --verbose`. `run-parts` itself
ships with Debian's `debianutils`, so relying on it would break the host-side
`initializeCommand` on a macOS host.

To add your own step, drop an executable file into either directory. Names may
only contain letters, digits, `_` and `-` — that is `run-parts`' own rule, and it
means extensions such as `.sh` are silently skipped.

### Running a dev container from inside the container

Thanks to the `docker-in-docker` feature, a project's own `devcontainer.json`
can be built and started from inside this container with either CLI:

```sh
devcontainer up --workspace-folder .
devpod up .
```

The `docker` provider is registered at image build time and is therefore already
DevPod's default provider, so it targets the local Docker daemon and needs no
further setup. Enter the workspace from a shell:

```sh
devpod ssh <workspace>
```

Three DevPod defaults are changed for this template:

- The default IDE is `none` (`devpod ide use none`), because DevPod otherwise
  falls back to opening VS Code and there is none to open in here. Pass
  `--ide vscode --open-ide=false` to `devpod up` if you want its server backend
  installed so that you can attach to the workspace later.
- Telemetry, through the `DEVPOD_DISABLE_TELEMETRY` environment variable,
  because the firewall blocks its endpoint anyway.
- Git credential and ssh signature forwarding (`SSH_INJECT_GIT_CREDENTIALS`,
  `GIT_SSH_SIGNATURE_FORWARDING`), because both work by editing `~/.gitconfig`
  inside the workspace. Here that file is a symlink into `/dev_container_home`,
  so DevPod would write through it into the configuration shared with the host
  and leave behind helpers pointing at paths that exist only inside the
  workspace. Re-enable them with `devpod context set-options` if you need git
  credentials forwarded and can live with that.

### Running Claude Desktop

[Claude Desktop](https://code.claude.com/docs/en/desktop-linux) is installed
from Anthropic's apt repository at image build time. Start it from a shell in
the container:

```sh
claude-desktop
```

Its window opens on the desktop of the host, because `devcontainer.json`
bind-mounts the Wayland socket of the host session:

```text
${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}   (host)
  -> /run/xdg_runtime_dir/wayland-0     (container)
```

The container side is `/run/xdg_runtime_dir` and not something under `/tmp`,
because the `docker-in-docker` feature mounts a tmpfs over `/tmp` while the
container starts, which would hide the socket mounted underneath it.

Both variables are read on the host, so they have to be visible to the process
that starts the container, exactly like `DOT_DEVCONTAINER_HOME`. That is the
case in a normal Wayland session; if the container is started from somewhere
else, export them there.

Nothing else of the host session is shared: the socket is mounted on its own,
not the whole `XDG_RUNTIME_DIR`, so the D-Bus, PipeWire, ssh-agent and gnupg
sockets that usually sit next to it stay outside the container.

The `claude-desktop` that `PATH` finds is
`.devcontainer/claude-desktop-wrapper.sh`, installed as
`/usr/local/bin/claude-desktop`. It only adds `--ozone-platform=wayland` to the
packaged `/usr/bin/claude-desktop`, which would otherwise look for an X server
that does not exist here.

`initialize_command.d/20-wayland` checks the socket on the host before the
container is created, and stops with an explanation when it is missing.
**Without a Wayland session on the host there is nothing to mount**, so on such
a host (X11-only, or macOS) remove the mount that ends in
`/run/xdg_runtime_dir/wayland-0` from `.devcontainer/devcontainer.json`. The
rest of the container works without it.

The desktop app does not update itself on Linux. New versions arrive with apt:

```sh
sudo apt-get update && sudo apt-get install --only-upgrade claude-desktop
```

## Firewall Configuration

By default, traffic to major services like GitHub, RubyGems, npm, Node.js, Google, and Microsoft is allowed.

To add allowed hosts, create a new file in `.devcontainer/allow_hosts.d/` and list domain names or IP addresses (one per line).

Example: `99-my-service`
```text
api.example.com
1.2.3.4
```

To apply changes inside the container, run:
```bash
.devcontainer/post_start_command.d/00-firewall
```

## Prerequisites

- Docker Desktop or Docker Engine
- Visual Studio Code
- [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
- The container requires `NET_ADMIN` capability. It may not work in some restricted environments.
- A Wayland session on the host, whose socket is mounted into the container so that Claude Desktop has somewhere to draw. See [Running Claude Desktop](#running-claude-desktop) for what to change when there is none.

## License

See [LICENSE.txt](LICENSE.txt).
