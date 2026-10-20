# dot-devcontainer

[![License X11](https://img.shields.io/badge/license-X11-blue.svg)](https://raw.githubusercontent.com/nishidayuya/dot-devcontainer/main/LICENSE.txt)
[![Latest tag](https://img.shields.io/github/v/tag/nishidayuya/dot-devcontainer)](https://github.com/nishidayuya/dot-devcontainer/tags)

A Dev Container configuration template pre-installed with `mise` and `Antigravity CLI`, featuring network access control (allowlist approach) via firewall.

## Features

- **Tool Management:** Manage Node.js, Ruby, and other tools using `mise`.
- **AI Integration:** Comes with `Antigravity CLI` (`agy`) pre-installed.
- **Nested dev containers:** Both the `Dev Container CLI` (`devcontainer`) and the `DevPod CLI` (`devpod`) are pre-installed, so a project's dev container can be built and started from inside this one.
- **Security:** Outbound network traffic is restricted using `iptables` to only allow connections to specified hosts.
- **Extensibility:** Easily add allowed hosts by adding files to `.devcontainer/allow_hosts.d/`, and allowed networks by adding files to `.devcontainer/allow_networks.d/`.
- **Local network access:** The private ranges of RFC 1918 are reachable on every port, so a service running on the host or on another machine on the LAN can be used from inside the container. The host itself is reachable as `host.docker.internal`, on Linux as well as on Docker Desktop.
- **Shell drop-in directories:** `~/.bashrc` and `~/.zshrc` source every file in `~/.bashrc.local.d/` and `~/.zshrc.local.d/`, in alphabetical order.
- **GPU access:** An NVIDIA GPU on the host can be passed to the container through `.devcontainer/.env.additional`, and a host without a GPU starts the container as before.
- **Independent home directory:** The directory pointed to by `DOT_DEVCONTAINER_HOME` on the host is mounted at `/dev_container_home`, and its entries are symlinked into the container home directory on start. Your real home directory is never mounted.

## Stack

- **OS:** Debian 13 (Bookworm)
- **Package Managers:** `apt`, `gem` (`npm` and `cargo` are available once Node.js and Rust are enabled in the `Dockerfile`)
- **Key Tools:**
  - `mise`
  - `gh` (GitHub CLI)
  - `glab` (GitLab CLI)
  - `docker-in-docker`
  - `devcontainer` (Dev Container CLI)
  - `devpod` (DevPod CLI, with the built-in `docker` provider)
  - `Antigravity CLI`
  - `Chromium` & `Chromium Driver`

## Usage

### Install into an existing project

Run the following command in your project root to install the `.devcontainer` directory:

```sh
curl -fsSL --retry 3 --retry-all-errors https://raw.githubusercontent.com/nishidayuya/dot-devcontainer/main/install.sh | sh
```

To pin a specific version, set `DOT_DEVCONTAINER_REF` to a tag from the
[tag list](https://github.com/nishidayuya/dot-devcontainer/tags), and fetch
`install.sh` from that same ref so that the installer and the installed files
stay in sync:

```sh
DOT_DEVCONTAINER_REF=v4.0.0
curl -fsSL --retry 3 --retry-all-errors "https://raw.githubusercontent.com/nishidayuya/dot-devcontainer/$DOT_DEVCONTAINER_REF/install.sh" |
  DOT_DEVCONTAINER_REF="$DOT_DEVCONTAINER_REF" sh
```

`DOT_DEVCONTAINER_REF` accepts any Git ref — a tag, a branch name, or a commit
SHA. It defaults to `main`.

For [`git-cococo`](https://github.com/nishidayuya/git-cococo) junkies:

```sh
DOT_DEVCONTAINER_REF="$(git ls-remote https://github.com/nishidayuya/dot-devcontainer.git refs/heads/main | awk '{print($1)}')" && git cococo sh -eux -c "curl -fsSL --retry 3 --retry-all-errors https://github.com/nishidayuya/dot-devcontainer/raw/$DOT_DEVCONTAINER_REF/install.sh | DOT_DEVCONTAINER_REF=$DOT_DEVCONTAINER_REF sh"
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

The scripts in `.devcontainer/initialize_command.d/` run the same way, but on the **host** and before the container is created.

Both directories are driven by `.devcontainer/run-parts.sh`, a POSIX `sh`
reimplementation of `run-parts --exit-on-error --verbose`. `run-parts` itself
ships with Debian's `debianutils`, so relying on it would break the host-side
`initializeCommand` on a macOS host.

To add your own step, drop an executable file into either directory. Names may
only contain letters, digits, `_` and `-` — that is `run-parts`' own rule, and it
means extensions such as `.sh` are silently skipped.

### Using an NVIDIA GPU

`devcontainer.json` cannot ask for a GPU only on the hosts that have one:
`runArgs` with `--gpus all` makes the container fail to start on a host without
a GPU, and DevPod ignores `hostRequirements.gpu`. So the GPU is requested per
host instead, through the NVIDIA runtime and the environment variables in
`.devcontainer/.env.additional`, which `runArgs` passes to `--env-file`.

1. On the host, install the NVIDIA driver and the NVIDIA Container Toolkit, and
   make the NVIDIA runtime Docker's default:

   ```sh
   sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
   sudo systemctl restart docker
   ```

2. Add the following to `.devcontainer/.env.additional` on that host:

   ```text
   NVIDIA_VISIBLE_DEVICES=all
   NVIDIA_DRIVER_CAPABILITIES=compute,utility
   ```

3. Rebuild the container, and check that `nvidia-smi` shows the GPU inside it.

On a host without the NVIDIA runtime, the variables are just ordinary
environment variables and do nothing. Note that the default runtime applies to
every container on the host, so any other container that sets
`NVIDIA_VISIBLE_DEVICES`, as the CUDA base images do, gets the GPUs as well.

### Customizing the shell

`~/.bashrc` and `~/.zshrc` end with a loop that sources every file in
`~/.bashrc.local.d/` and `~/.zshrc.local.d/` respectively, in alphabetical
order. Both directories are optional: a missing or empty one is simply skipped,
and so is anything in them that is not a regular file.

Because they are sourced last, they can override the `mise` activation that the
image sets up. And because they live in the home directory, the usual way to
fill them is to put them in `DOT_DEVCONTAINER_HOME` and let
`post_start_command.d/10-dev-container-home` symlink them in:

```text
~/dev_container_home/
└── .bashrc.local.d/
    └── 50-aliases
```

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

## Firewall Configuration

### Allowed hosts

`.devcontainer/allow_hosts.d/` ships empty and is ignored by git, so each
workspace decides its own allowed hosts. `.devcontainer/allow_hosts.d.example/`
holds ready-made files for major services like GitHub, GitLab, RubyGems, npm,
Node.js, Google, and Microsoft; copy the ones you need:

```sh
cp -p .devcontainer/allow_hosts.d.example/* .devcontainer/allow_hosts.d/
```

To add allowed hosts, create a new file in `.devcontainer/allow_hosts.d/` and list domain names or IP addresses (one per line).

Example: `99-my-service`
```text
api.example.com
1.2.3.4
```

Each of those entries is granted ports 80 and 443 only.

### Allowed networks

Whole networks are listed separately, in `.devcontainer/allow_networks.d/`, one
IPv4 address or CIDR block per line. Unlike an `allow_hosts.d` entry, a network
listed here is allowed on **every port and every protocol** — which is what
reaching a local service takes, since it is as likely to sit on 5432, 3000 or
11434 as on 443. Domain names are rejected: a network has to be a fixed range,
not something resolved once at startup. Comments and blank lines are ignored.

Like `allow_hosts.d/`, `.devcontainer/allow_networks.d/` ships empty and is
ignored by git. `.devcontainer/allow_networks.d.example/` holds the private
ranges of RFC 1918 in three files, one range each; copy the ones you need to
make the local network reachable:

```sh
cp -p .devcontainer/allow_networks.d.example/* .devcontainer/allow_networks.d/
```

| File                | Network          |
| ------------------- | ---------------- |
| `50-private-classA` | `10.0.0.0/8`     |
| `50-private-classB` | `172.16.0.0/12`  |
| `50-private-classC` | `192.168.0.0/16` |

`172.16.0.0/12` matters even when no LAN is involved: the container's default
gateway is the Docker bridge (usually `172.17.0.1`), so this is what lets it
reach a service published on the host, and the bridge that `docker-in-docker`
gives nested containers falls in the same range.

### Reaching the host

`devcontainer.json` passes `--add-host=host.docker.internal:host-gateway` to
`docker run`, so `host.docker.internal` resolves to the host's address on the
Docker bridge. Docker Desktop provides the name on its own, but Docker Engine on
Linux does not without this. Since that address is in `172.16.0.0/12`, every
port on it is reachable through the firewall once `50-private-classB` is in
`allow_networks.d/`:

```sh
curl http://host.docker.internal:3000/
```

The service on the host has to listen on that address, though. One bound to
`127.0.0.1` only, as many dev servers are by default, cannot be reached from the
container; bind it to `0.0.0.0` or to the bridge address instead. A firewall on
the host, such as `ufw`, may also need to let the bridge in.

The link-local range `169.254.0.0/16` is deliberately left out: it carries the
cloud metadata service (`169.254.169.254`), which hands instance credentials to
anything that asks it.

This does trade away part of what an allowlist buys — every host on the local
network becomes reachable on every port. Delete one of the `50-private-*` files to
close off that range, or all three to keep the container confined to the hosts
in `allow_hosts.d`.

Note that only outbound traffic is filtered at all: the `INPUT` chain is left
open, so connecting **into** the container from the host has always worked and
is unaffected by any of this.

### Applying changes

To apply changes inside the container, run:
```bash
.devcontainer/post_start_command.d/00-firewall
```

## Prerequisites

- Docker Desktop or Docker Engine
- Visual Studio Code
- [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
- The container requires `NET_ADMIN` capability. It may not work in some restricted environments.
- To use an NVIDIA GPU from inside the container, the host needs the NVIDIA driver and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html). See [Using an NVIDIA GPU](#using-an-nvidia-gpu).

## License

See [LICENSE.txt](LICENSE.txt).
