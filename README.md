# goconfig

A Go installation and version manager for Linux and macOS.

## Features

- Install, update, and remove Go with a single command
- Multi-version management: install and switch between multiple Go versions
- Automatic environment configuration (GOPATH, PATH)
- Download caching for faster reinstalls
- Checksum verification for secure downloads
- Proxy support for corporate environments
- Shell completions for bash and zsh
- Self-update capability

## Supported Platforms

- **Operating Systems:** Linux, macOS
- **Architectures:** amd64 (x86_64), arm64 (aarch64), ppc64le, s390x

## Requirements

- `wget` or `curl`
- `tar`

## Usage

```bash
./go.sh [OPTIONS] <COMMAND> [ARGS]
```

### Options

| Option | Description |
|--------|-------------|
| `-q, --quiet` | Suppress non-error output |
| `-v, --verbose` | Enable verbose/debug output |
| `--version` | Show goconfig version |

### Commands

#### Installation & Updates

| Command | Description |
|---------|-------------|
| `install` | Install the latest Go version |
| `install <VERSION>` | Install a specific Go version (e.g., `1.22.0`) |
| `remove` | Remove Go installation |
| `remove --env` | Remove Go installation and shell configuration |
| `update` | Update Go to the latest version |

#### Environment

| Command | Description |
|---------|-------------|
| `env` | Set up Go environment variables in your shell config |

#### Version Management

| Command | Description |
|---------|-------------|
| `versions` | List all available Go versions (remote) |
| `list` | List locally installed Go versions |
| `use <VERSION>` | Switch to a specific installed version |

#### Maintenance

| Command | Description |
|---------|-------------|
| `status` | Show installation status and health check |
| `cache` | Manage download cache (clear) |
| `config` | Show current configuration |
| `config save` | Save current configuration to file |
| `self-update` | Update goconfig to the latest version |
| `completions [bash\|zsh]` | Generate shell completions |
| `help` | Show help message |

## Examples

```bash
# Install the latest Go version
./go.sh install

# Install a specific version
./go.sh install 1.22.0

# Update to the latest version
./go.sh update

# Check installation status
./go.sh status

# List available versions
./go.sh versions

# Switch between installed versions
./go.sh use 1.21.0

# Generate and install bash completions
./go.sh completions bash >> ~/.bashrc
```

## Configuration

goconfig can be configured via environment variables or a config file (`~/.goconfig`).

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GO_INSTALL_DIR` | `/usr/local` | Go installation directory |
| `GO_WORKSPACE` | `$HOME/go` | Go workspace (GOPATH) |
| `GO_VERSIONS_DIR` | `$HOME/.go/versions` | Directory for multiple Go versions |
| `GO_CACHE_DIR` | `$HOME/.cache/goconfig` | Download cache directory |
| `HTTP_PROXY` | - | HTTP proxy for downloads |
| `HTTPS_PROXY` | - | HTTPS proxy for downloads |

### Custom Installation Directory

To install Go to a user-writable location (no sudo required):

```bash
export GO_INSTALL_DIR="$HOME/.local"
./go.sh install
```

## License

Apache License, Version 2.0

## Contributors

- Rafael Sene <rpsene@gmail.com>
- Hiro Miyamoto <miyamotoh@fuji.waseda.jp>
