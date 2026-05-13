# AI Smart Installer — v2.0

![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/platform-Linux-blue)
![Platform](https://img.shields.io/badge/platform-Windows-blue)
![Platform](https://img.shields.io/badge/platform-MacOS-blue)
![VSCode](https://img.shields.io/badge/vscode-Continue%20Ready-007ACC)
![AI](https://img.shields.io/badge/local--ai-ollama-orange)
![Status](https://img.shields.io/badge/status-production--ready-brightgreen)

---

> One-script local AI setup for VSCode.
> Installs Ollama, fetches models from the live library, filters them by your hardware, configures the Continue extension — all automatically.

---
![Command Gif](https://i.postimg.cc/Kcfs16k3/In-Shot-20260513-023053831-ezgif-com-video-to-gif-converter.gif)
---

## Author

# **Moshiur Rahman Deap**

> Full-stack Developer | AI Automation Builder

Portfolio: [Moshiur Rahman Deap](https://moshiurrahman.online)  
 GitHub: [Click Here](https://github.com/moshiurrahmandeap11)

---
## Installation

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/moshiurrahmandeap11/Just-one/main/setup.sh | bash
```

### MacOS

```bash
coming soon
```

### Microsoft Windows

---

## Ready Your PowerShell

- Open PowerShell as Administrator
- Or press `Win + X` → Windows PowerShell (Admin)

```bash
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Clone the repo

```bash
https://github.com/moshiurrahmandeap11/Just-one
```

### change the directory

```bash
cd Just-one
```

### Run the script:

```bash
.\setup.ps1
```
---

## Preview

![Banner and System Info](https://i.postimg.cc/kXQtgsRz/just-One1.jpg)

![Model Recommendation Table](https://i.postimg.cc/HWc8TLzh/Screenshot-2026-05-13-163251.png)

---

## What It Does

| Step | Action                                                         |
| ---- | -------------------------------------------------------------- |
| 1    | Detects your Linux distribution and installs `curl` if missing |
| 2    | Reads your CPU, RAM, GPU, VRAM and free disk space             |
| 3    | Installs Ollama via the official installer script              |
| 4    | Starts the Ollama background server                            |
| 5    | Verifies VSCode CLI and installs the Continue extension        |
| 6    | Fetches the full live model list from `ollama.com/library`     |
| 7    | Filters models by your available memory — no hardcoded lists   |
| 8    | Lets you pick models interactively from a numbered table       |
| 9    | Pulls selected models and guarantees the fallback is installed |
| 10   | Writes a complete `~/.continue/config.yaml`                    |
| 11   | Opens VSCode in the current directory                          |

---

## Requirements

- Linux (any major distribution)
- Bash 4+
- `sudo` access (for package installation if `curl` is missing)
- VSCode with the `code` CLI command enabled
- Internet connection
---

## Linux Supported Distributions

| Distro Family                   | Package Manager |
| ------------------------------- | --------------- |
| Ubuntu, Debian, Mint, Pop, Kali | `apt`           |
| Fedora                          | `dnf`           |
| CentOS, RHEL, AlmaLinux, Rocky  | `yum`           |
| Arch, Manjaro, EndeavourOS      | `pacman`        |
| openSUSE, SLES                  | `zypper`        |
| Alpine                          | `apk`           |
| Void Linux                      | `xbps`          |

---

## Model Filtering Logic

The script never hardcodes models. Every run fetches the live list from `ollama.com/library`.

Models are then filtered using **pure name-based size estimation** — zero extra network calls, instant result:

```
size_GB = ceil( param_count × 0.55 )    # 4-bit quantisation estimate
```

Only models that fit within **65% of your effective memory** are shown, keeping the OS and other processes stable during inference.

**Memory priority:**

```
GPU VRAM ≥ 8 GB  →  use VRAM   (GPU-accelerated inference)
otherwise        →  use System RAM
```

**Profile labels shown in the table:**

| Label         | Estimated Size |
| ------------- | -------------- |
| `lightweight` | ≤ 2 GB         |
| `balanced`    | 3 – 6 GB       |
| `heavy`       | 7 GB +         |

---

## Default Fallback Model

`qwen2.5-coder:1.5b` is always installed regardless of your selection.

It is configured as `roles: [autocomplete]` only — a small, fast model dedicated to tab-autocomplete so it never competes with your main chat model.

---

## Continue Config Output

The generated `~/.continue/config.yaml` looks like this:

```yaml
name: Local AI Config
version: 1.0.0
schema: v1

models:
  - name: mistral
    provider: ollama
    model: mistral
    roles: [chat, autocomplete]

  - name: qwen2.5-coder:1.5b
    provider: ollama
    model: qwen2.5-coder:1.5b
    roles: [autocomplete]

context:
  - provider: code
  - provider: docs
  - provider: diff
  - provider: terminal
  - provider: problems
  - provider: folder
  - provider: codebase

tabAutocomplete:
  disable: false

slashCommands:
  - name: edit
    description: Edit selected code
  - name: comment
    description: Add comments to code
  - name: share
    description: Export conversation
  - name: cmd
    description: Generate a shell command
```

---

## Interactive Model Selection

After the table is displayed, enter the row numbers of the models you want to install, separated by commas:

```
Your choice:  1,4,7
```

Press **Enter** with no input to skip and use only the fallback model.

---

## Troubleshooting

**Continue extension fails to install**

The `code --install-extension` command requires access to `*.vsassets.io`. If you are behind a restrictive firewall or DNS block, install it manually:

1. Open VSCode
2. Go to Extensions (`Ctrl+Shift+X`)
3. Search for **Continue**
4. Click Install

**Ollama server does not start**

```bash
ollama serve
```

Run this manually in a separate terminal and then re-run the script.

**No models appear in the table**

Your RAM may be too low for the 65% threshold. The fallback `qwen2.5-coder:1.5b` (~1 GB) will still be installed automatically.

**GPU not detected**

The script detects NVIDIA via `nvidia-smi` and AMD via `rocm-smi`. If neither is installed, it falls back to system RAM for model sizing. Install the appropriate driver package to enable GPU detection.

---

## Author

**moshiurrahmandeap11**
GitHub — [github.com/moshiurrahmandeap11](https://github.com/moshiurrahmandeap11)

---

## License

MIT — free to use, modify and distribute.
