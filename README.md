# Just One Installer — v2.5

![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/platform-Linux%20|%20macOS%20|%20Windows-blue)
![Editors](https://img.shields.io/badge/editors-VSCode%20|%20Cursor%20|%20VSCodium-007ACC)
![AI](https://img.shields.io/badge/local--ai-ollama%20+%20continue-orange)
![RAG](https://img.shields.io/badge/codebase--rag-nomic--embed--text-purple)
![Status](https://img.shields.io/badge/status-production--ready-brightgreen)

> **One-command zero-config local AI setup for your code editor.**  
> Installs Ollama, fetches models, filters them safely by your hardware, sets up Codebase RAG embeddings, and configures the Continue extension across **VS Code, Cursor, and VSCodium** — completely automatically.

🌐 **Live Web Landing Page & Hardware Calculator:** [https://just-one-tau.vercel.app/](https://just-one-tau.vercel.app/)

![Command Gif](https://i.postimg.cc/Kcfs16k3/In-Shot-20260513-023053831-ezgif-com-video-to-gif-converter.gif)

---

## Author

# **Moshiur Rahman Deap**

> Full-stack Developer | AI Automation Builder

- **Portfolio:** [moshiur.pro](https://moshiur.pro)  
- **GitHub:** [github.com/moshiurrahmandeap11](https://github.com/moshiurrahmandeap11)
- **LinkedIn:** [linkedin.com/in/moshiurrahmandeap](https://linkedin.com/in/moshiurrahmandeap)

---

## One-Line Installation

### Microsoft Windows (PowerShell)
Open PowerShell (or Windows Terminal) and run:

```powershell
irm https://just-one-tau.vercel.app/windows | iex
```

---

### macOS (Terminal)
Open Terminal and run:

```bash
curl -fsSL https://just-one-tau.vercel.app/mac | bash
```

---

### Linux (Any major distribution)
Open Terminal and run:

```bash
curl -fsSL https://just-one-tau.vercel.app/linux | bash
```

---

## What Just One Does Automatically

| Step | Action |
| :--- | :--- |
| 1 | **System Hardware Profiling**: Detects CPU cores, RAM, GPU/VRAM, and free disk space. |
| 2 | **GPU Acceleration Optimizations**: Sets `OLLAMA_FLASH_ATTENTION=1` and `24h` model keep-alive. |
| 3 | **Ollama Installation**: Installs Ollama and starts the local background server daemon. |
| 4 | **Multi-Editor Detection**: Checks for **VS Code**, **Cursor**, **VS Code Insiders**, or **VSCodium** and installs the Continue extension. |
| 5 | **Live Model Discovery**: Fetches model families from `ollama.com/library` and filters them by memory footprint. |
| 6 | **1-Click Quick Setup or Custom Table**: Choose between 1-click recommended setup or custom selection. |
| 7 | **Tab-Autocomplete Model**: Guarantees fast local FIM model (`qwen2.5-coder:1.5b`) for instant tab completions. |
| 8 | **Codebase RAG Embedding Model**: Automatically installs `nomic-embed-text` so `@codebase` semantic indexing works immediately. |
| 9 | **Configuration & Rules**: Generates `~/.continue/config.yaml` and `~/.continue/.continuerules`. |
| 10 | **Editor Launch**: Automatically launches your code editor in the current directory ready for local AI pairing. |

---

## Smart Hardware-Adaptive Presets

You can choose between **1-Click Quick Setup** or **Custom Selection**:

### ⚡ Mode 1: Quick Setup (Auto-Engineered for your specs)

| Hardware Tier | Primary Chat/Edit Model | Fast Tab-Autocomplete | Codebase RAG |
| :--- | :--- | :--- | :--- |
| **8 GB RAM** | `qwen2.5-coder:3b` | `qwen2.5-coder:1.5b` | `nomic-embed-text` |
| **16 GB RAM / 8GB VRAM** | `qwen2.5-coder:7b` + `deepseek-r1:7b` | `qwen2.5-coder:1.5b` | `nomic-embed-text` |
| **24 GB+ RAM / 12GB+ VRAM**| `qwen2.5-coder:14b` + `deepseek-r1:8b` | `qwen2.5-coder:1.5b` | `nomic-embed-text` |

### 🛠️ Mode 2: Custom Selection
Browse an interactive numbered CLI table categorized by role (`[Coder]`, `[Reasoning]`, `[Vision]`, `[General]`) and enter comma-separated numbers (e.g. `1,3`).

---

## 65% Memory Budget Safety Rule

The installer uses a safe 4-bit quant estimation formula:
$$\text{size\_GB} = \lceil \text{parameters} \times 0.55 \rceil$$

Only models that comfortably fit within **65% of your effective memory** (GPU VRAM or System RAM) are made available. This guarantees your system stays responsive and never locks up or crashes during heavy inference.

---

## Continue Configuration Output (`config.yaml`)

The generated `~/.continue/config.yaml` is pre-configured with pure YAML and production-ready defaults:

```yaml
name: Local AI Config
version: 1.0.0
schema: v1

models:
  - name: qwen2.5-coder:7b
    provider: ollama
    model: qwen2.5-coder:7b
    roles: [chat, edit]

  - name: deepseek-r1:7b
    provider: ollama
    model: deepseek-r1:7b
    roles: [chat, edit]

  - name: qwen2.5-coder:1.5b
    provider: ollama
    model: qwen2.5-coder:1.5b
    roles: [autocomplete]

embeddingsProvider:
  provider: ollama
  model: nomic-embed-text

tabAutocompleteModel:
  title: Tab Autocomplete
  provider: ollama
  model: qwen2.5-coder:1.5b

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
  - name: test
    description: Generate unit tests for selected code
  - name: refactor
    description: Refactor code for cleanliness, performance, and best practices
  - name: fix
    description: Detect bugs, syntax errors, and security issues
  - name: explain
    description: Explain the highlighted code in detail
  - name: comment
    description: Add comprehensive docstrings and comments
  - name: share
    description: Export conversation
  - name: cmd
    description: Generate shell command
```

---

## Pre-Configured Developer Rules (`.continuerules`)

A clean development guide is automatically written to `~/.continue/.continuerules` to keep your AI code generation professional:
- Write clean, modular, modern, and well-typed code.
- Always include error handling and handle edge cases gracefully.
- Follow idioms and conventions of the target language.
- Do not leave placeholder comments without implementation.

---

## Multi-Editor Support

Just One automatically detects the first available editor CLI on your `PATH`:
- **VS Code** (`code`)
- **Cursor AI** (`cursor`)
- **VS Code Insiders** (`code-insiders`)
- **VSCodium** (`codium`)

---

## Supported Linux Distributions

| Distro Family | Package Manager |
| :--- | :--- |
| Ubuntu, Debian, Mint, Pop, Kali | `apt` |
| Fedora | `dnf` |
| CentOS, RHEL, AlmaLinux, Rocky | `yum` |
| Arch, Manjaro, EndeavourOS | `pacman` |
| openSUSE, SLES | `zypper` |
| Alpine | `apk` |
| Void Linux | `xbps` |

---

## Author & Community

**Moshiur Rahman Deap**  
- GitHub: [github.com/moshiurrahmandeap11](https://github.com/moshiurrahmandeap11)  
- Website: [moshiurrahman.online](https://moshiurrahman.online)

---

## License

MIT — Free to use, modify, and distribute for personal and commercial projects.
