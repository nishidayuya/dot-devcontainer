# dot-devcontainer

A Dev Container configuration template pre-installed with `mise` and `Gemini CLI`, featuring network access control (allowlist approach) via firewall.

## Features

- **Tool Management:** Manage Node.js, Ruby, and other tools using `mise`.
- **AI Integration:** Comes with `Gemini CLI` (`@google/gemini-cli`) pre-installed.
- **Security:** Outbound network traffic is restricted using `iptables` to only allow connections to specified hosts.
- **Extensibility:** Easily add allowed hosts by adding files to `.devcontainer/allow_hosts.d/`.

## Stack

- **OS:** Debian 13 (Bookworm)
- **Package Managers:** `apt`, `npm`, `gem`
- **Key Tools:**
  - `mise`
  - `gh` (GitHub CLI)
  - `docker-in-docker`
  - `Gemini CLI`
  - `Chromium` & `Chromium Driver`

## Usage

### Install into an existing project

Run the following command in your project root to install the `.devcontainer` directory:

```bash
curl -f -sL https://raw.githubusercontent.com/nishidayuya/dot-devcontainer/main/install.sh | sh
```

### Starting the Dev Container

1. Open your project in VS Code.
2. Run the `Dev Containers: Reopen in Container` command.
3. `.devcontainer/setup-firewall.sh` will run automatically on start to apply the firewall rules.

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
