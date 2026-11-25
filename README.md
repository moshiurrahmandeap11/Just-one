# Just One Installer — v2.5

![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/platform-Linux%20|%20macOS%20|%20Windows-blue)
![Editors](https://img.shields.io/badge/editors-VSCode%20|%20Cursor%20|%20VSCodium-007ACC)
![AI](https://img.shields.io/badge/local--ai-ollama%20+%20continue-orange)
![RAG](https://img.shields.io/badge/codebase--rag-nomic--embed--text-purple)
![Status](https://img.shields.io/badge/status-production--ready-brightgreen)

> **One-command zero-config local AI setup for your code editor.**  
> Installs Ollama, fetches models, filters them safely by your hardware, sets up Codebase RAG embeddings, and configures the Continue extension across **VS Code, Cursor, and VSCodium** — completely automatically.

🌐 **Live Web Landing Page & Hardware Calculator:** [https://one.moshiur.pro/](https://one.moshiur.pro/)

![Command Gif](https://i.postimg.cc/Kcfs16k3/In-Shot-20260513-023053831-ezgif-com-video-to-gif-converter.gif)

---

## Author

### **Moshiur Rahman Deap**

> Full-stack Developer | AI Automation Builder

- **Portfolio:** [moshiur.pro](https://moshiur.pro)  
- **GitHub:** [github.com/moshiurrahmandeap11](https://github.com/moshiurrahmandeap11)
- **LinkedIn:** [linkedin.com/in/moshiurrahmandeap](https://linkedin.com/in/moshiurrahmandeap)

---

## One-Line Installation

### Microsoft Windows (PowerShell)
Open PowerShell (or Windows Terminal) and run:

```powershell
irm https://one.moshiur.pro/windows | iex
```

---

### macOS (Terminal)
Open Terminal and run:

```bash
curl -fsSL https://one.moshiur.pro/mac | bash
```

---

### Linux (Any major distribution)
Open Terminal and run:

```bash
curl -fsSL https://one.moshiur.pro/linux | bash
```

---

## What Just One Does Automatically

| Step | Action |
| :--- | :--- |
| 1 | **System Hardware Profiling**: Detects CPU threads, RAM, GPU/VRAM, and free disk space with a live 65% memory budget bar. |
| 2 | **Ollama Runtime & Optimizations**: Sets `OLLAMA_FLASH_ATTENTION=1` & `24h` keep-alive, installs Ollama, and waits for the local API. |
| 3 | **All-Editor Auto-Setup**: Detects **VS Code**, **Cursor**, **VS Code Insiders**, and **VSCodium** simultaneously and installs Continue in all of them. |
| 4 | **Live Model Discovery**: Fetches model families from `ollama.com/library` and filters them by memory footprint. |
| 5 | **Express or Custom Mode Picker**: Interactive `↑/↓` arrow menu to pick 1-click Express Setup or Custom Model Selection (set `JUST_ONE_AUTO=1` for hands-free mode). |
| 6 | **Models + Tab-Autocomplete + RAG**: Pulls your coding/reasoning models, `qwen2.5-coder:1.5b` (FIM autocomplete), and `nomic-embed-text` (`@codebase` RAG). |
| 7 | **Safe Backup & YAML v1 Config**: Backs up any existing `config.yaml` and generates pure `schema: v1` `~/.continue/config.yaml` + `.continuerules`. |
| 8 | **Live RAG Health Check & Launch**: Verifies local embeddings via `/api/embeddings` and launches your editor ready to code. |

---

## Smart Hardware-Adaptive Presets

You can choose between **1-Click Quick Setup** or **Custom Selection**:

### ⚡ Mode 1: Quick Setup (Auto-Engineered for your specs)

| Hardware Tier | Primary Chat/Edit Model | Fast Tab-Autocomplete | Codebase RAG |
| :--- | :--- | :--- | :--- |
| **< 8 GB RAM** | `qwen2.5-coder:3b` | `qwen2.5-coder:1.5b` | `nomic-embed-text` |
| **8 GB RAM / 8 GB VRAM** | `qwen2.5-coder:7b` | `qwen2.5-coder:1.5b` | `nomic-embed-text` |
| **12 GB+ VRAM / 16 GB RAM** | `qwen2.5-coder:7b` + `deepseek-r1:7b` | `qwen2.5-coder:1.5b` | `nomic-embed-text` |
| **24 GB+ RAM / 24 GB+ VRAM**| `qwen2.5-coder:14b` + `deepseek-r1:8b` | `qwen2.5-coder:1.5b` | `nomic-embed-text` |

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
    roles:
      - chat
      - edit
      - apply

  - name: deepseek-r1:7b
    provider: ollama
    model: deepseek-r1:7b
    roles:
      - chat
      - edit
      - apply

  - name: qwen2.5-coder:1.5b
    provider: ollama
    model: qwen2.5-coder:1.5b
    roles:
      - autocomplete

  - name: nomic-embed-text
    provider: ollama
    model: nomic-embed-text
    roles:
      - embed

context:
  - provider: code
  - provider: docs
  - provider: diff
  - provider: terminal
  - provider: problems
  - provider: folder
  - provider: codebase
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
- Website: [moshiur.pro](https://moshiur.pro)

---

## License

MIT — Free to use, modify, and distribute for personal and commercial projects.
