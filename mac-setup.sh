#!/bin/bash

# ──────────────────────────────────────────────────────────────────
#  AI Smart Installer  |  VSCode + Ollama + Continue  |  v2.0
#  macOS Version
#  Author : Moshiur Rahman Deap
#  Github : https://github.com/moshiurrahmandeap11
#  Contact: https://linkedin.com/in/moshiurrahmandeap
#  License: MIT
# ──────────────────────────────────────────────────────────────────

clear
set -e

# ── Terminal Styling ──────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'

# ── Logger Functions ──────────────────────────────────────────────
log()   { echo -e " ${BOLD}${GREEN} OK ${RESET}  ${BOLD}$1${RESET}"; }
warn()  { echo -e " ${BOLD}${YELLOW} >> ${RESET}  ${BOLD}$1${RESET}"; }
error() { echo -e " ${BOLD}${RED} !! ${RESET}  ${BOLD}$1${RESET}"; }
info()  { echo -e " ${BOLD}${CYAN} -- ${RESET}  $1"; }
blank() { echo ""; }

# ── Section Header ────────────────────────────────────────────────
# Draws a pixel-perfect double-line box with a centred title.
# Width is fixed at 56 chars to align consistently across sections.
section() {
    local title="$1"
    local width=56
    local line
    line=$(printf '═%.0s' $(seq 1 $width))
    local inner=$(( width - 2 ))
    local pad=$(( (inner - ${#title}) / 2 ))
    local lpad rpad spaces_l spaces_r
    spaces_l=$(printf ' %.0s' $(seq 1 $pad))
    rpad=$(( inner - ${#title} - pad ))
    spaces_r=$(printf ' %.0s' $(seq 1 $rpad))

    blank
    echo -e "${BOLD}${CYAN}  ╔${line}╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║${spaces_l}${WHITE}${title}${CYAN}${spaces_r}║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚${line}╝${RESET}"
    blank
}

# ── Banner ────────────────────────────────────────────────────────
# Shown once at the very start after clearing the terminal.
print_banner() {
    echo -e "${BOLD}${CYAN}"
    echo "  ╔════════════════════════════════════════════════════════╗"
    echo "  ║                                                        ║"
    echo "  ║           Just One Installer     v2.0                  ║"
    echo "  ║       VSCode  +  Ollama  +  Continue  Dev              ║"
    echo "  ║       Developed By Moshiur Rahman Deap                 ║"
    echo "  ║                                                        ║"
    echo "  ╚════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    blank
}

# ─────────────────────────────────────────────────────────────────
#  STEP 1  |  Ensure Homebrew is available
#  Homebrew is the package manager for macOS
# ─────────────────────────────────────────────────────────────────

ensure_homebrew() {
    section "Checking Homebrew"

    if command -v brew &>/dev/null; then
        log "Homebrew is already installed"
        return
    fi

    warn "Homebrew not found -- installing..."
    info "This requires administrator privileges"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    log "Homebrew installed successfully"
    # Add brew to PATH
    eval "$(/opt/homebrew/bin/brew shellenv)"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 2  |  Collect system hardware information
#  Reads CPU model and core count, total RAM, GPU name and VRAM.
# ─────────────────────────────────────────────────────────────────

detect_system() {
    section "System Information"

    CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo 2)
    CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown CPU")

    RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 8589934592)
    RAM_MB=$(( RAM_BYTES / 1024 / 1024 ))
    RAM_GB=$(( RAM_MB / 1024 ))

    GPU_VRAM=0
    GPU_NAME="Not detected"

    # macOS GPU detection is limited; assume integrated or basic detection
    if system_profiler SPDisplaysDataType 2>/dev/null | grep -q "Chipset Model"; then
        GPU_NAME=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | cut -d: -f2 | xargs || echo "Integrated GPU")
    fi

    DISK_FREE=$(df -BG "$HOME" 2>/dev/null | awk 'NR==2 {gsub("Gi",""); print $4}' || echo 20)

    echo -e "  ${BOLD}${WHITE}CPU        ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${CPU_MODEL}${RESET}  ${DIM}(${CPU_CORES} cores)${RESET}"
    echo -e "  ${BOLD}${WHITE}RAM        ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${RAM_GB} GB${RESET}  ${DIM}(${RAM_MB} MB)${RESET}"
    echo -e "  ${BOLD}${WHITE}GPU        ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${GPU_NAME}${RESET}"
    echo -e "  ${BOLD}${WHITE}VRAM       ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${GPU_VRAM} GB${RESET}"
    echo -e "  ${BOLD}${WHITE}Disk Free  ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${DISK_FREE} GB${RESET}"
    blank
}

# ─────────────────────────────────────────────────────────────────
#  STEP 3  |  Install and start Ollama
#  Uses Homebrew to install Ollama, then starts the server.
# ─────────────────────────────────────────────────────────────────

install_ollama() {
    section "Ollama Installation"

    if command -v ollama &>/dev/null; then
        log "Ollama is already installed"
        return
    fi

    warn "Installing Ollama via Homebrew..."
    brew install ollama
    log "Ollama installed successfully"
}

start_ollama() {
    if pgrep -x ollama &>/dev/null; then
        log "Ollama server is already running"
        return
    fi

    warn "Starting Ollama background server..."
    ollama serve > /dev/null 2>&1 &
    sleep 5
    log "Ollama server started"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 4  |  VSCode + Continue extension
#  Checks that the VSCode CLI is on PATH, then installs the
#  Continue AI extension if it is not already present.
# ─────────────────────────────────────────────────────────────────

check_vscode() {
    section "VSCode  +  Continue Extension"

    if ! command -v code &>/dev/null; then
        error "VSCode CLI not found  --  install VSCode and enable the 'code' command"
        echo -e "  ${DIM}https://code.visualstudio.com/download${RESET}"
        exit 1
    fi

    log "VSCode CLI found"
}

install_continue() {
    local extensions
    extensions=$(code --list-extensions 2>/dev/null)
    if echo "$extensions" | grep -q "Continue.continue"; then
        log "Continue extension is already installed"
        return
    fi

    warn "Installing Continue extension..."
    code --install-extension Continue.continue
    log "Continue extension installed"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 5  |  Fetch model list from Ollama library
# ─────────────────────────────────────────────────────────────────

fetch_models() {
    section "Fetching Ollama Model Library"

    info "Connecting to ollama.com/library..."

    if ! curl -s --max-time 10 "https://ollama.com/library" > /tmp/ollama_library.html 2>/dev/null; then
        warn "Could not reach ollama.com -- using built-in model list"
        use_builtin_models
        return
    fi

    log "Parsing model list from Ollama library..."

    # Extract model names from HTML
    models=$(grep -oP 'href="/library/\K[^"]+' /tmp/ollama_library.html | sort | uniq)
    rm -f /tmp/ollama_library.html

    if [ -z "$models" ]; then
        warn "No models found -- using built-in list"
        use_builtin_models
        return
    fi

    # Convert to array
    IFS=$'\n' read -r -d '' -a MODEL_LIST <<< "$models"

    log "Found ${#MODEL_LIST[@]} models"
}

use_builtin_models() {
    MODEL_LIST=(
        "llama3.2:1b" "llama3.2:3b" "llama3.1:8b" "llama3.1:70b" "llama3.1:405b"
        "mistral:7b" "mixtral:8x7b" "codellama:7b" "codellama:13b" "codellama:34b"
        "qwen2.5-coder:1.5b" "qwen2.5-coder:3b" "qwen2.5-coder:7b" "qwen2.5-coder:14b"
        "deepseek-coder:6.7b" "deepseek-coder:33b"
        "phi3:3.8b" "phi3.5:3.8b"
        "gemma2:2b" "gemma2:9b" "gemma2:27b"
        "starcoder2:3b" "starcoder2:7b" "starcoder2:15b"
    )
}

# ─────────────────────────────────────────────────────────────────
#  STEP 6  |  Show model recommendations
# ─────────────────────────────────────────────────────────────────

show_recommendations() {
    section "Model Recommendations"

    echo -e "  ${BOLD}${WHITE}Recommended models based on your system:${RESET}"
    blank

    local recommended=()

    if [ "$RAM_GB" -ge 16 ] && [ "$CPU_CORES" -ge 8 ]; then
        recommended=("llama3.1:8b" "codellama:13b" "qwen2.5-coder:7b")
    elif [ "$RAM_GB" -ge 8 ] && [ "$CPU_CORES" -ge 4 ]; then
        recommended=("llama3.2:3b" "codellama:7b" "qwen2.5-coder:3b")
    else
        recommended=("llama3.2:1b" "qwen2.5-coder:1.5b" "phi3:3.8b")
    fi

    for model in "${recommended[@]}"; do
        echo -e "  ${BOLD}${CYAN}• ${model}${RESET}"
    done

    blank
    echo -e "  ${DIM}Select models by entering their row numbers (e.g., 1,3,5)${RESET}"
    blank

    # Show already installed models
    echo -e "  ${BOLD}${WHITE}Already Installed:${RESET}"
    if command -v ollama &>/dev/null; then
        installed=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' | tr '\n' ' ')
        if [ -n "$installed" ]; then
            echo "$installed" | tr ' ' '\n' | sed 's/^/    /'
        else
            echo -e "    ${DIM}None${RESET}"
        fi
    else
        echo -e "    ${DIM}None${RESET}"
    fi
    blank
}

# ─────────────────────────────────────────────────────────────────
#  STEP 7  |  Interactive model selection
# ─────────────────────────────────────────────────────────────────

select_models() {
    echo -e "  ${BOLD}${WHITE}Select models to install:${RESET}"
    echo -e "  ${DIM}Enter row numbers separated by commas  (example:  1,3,5)${RESET}"
    echo -e "  ${DIM}Press Enter to skip and use the fallback model only${RESET}"
    blank
    echo -e "  ${BOLD}${CYAN}Your choice:  ${RESET}\c"
    read -r input

    SELECTED=()
    SUCCESSFUL_MODELS=()

    if [ -z "$input" ] || [ "$input" = "0" ]; then
        log "No selection -- fallback model will be used"
        return
    fi

    local numbers
    IFS=',' read -ra numbers <<< "$input"
    for num in "${numbers[@]}"; do
        num=$(echo "$num" | xargs)
        if [ -n "${MODEL_MAP[$num]}" ]; then
            SELECTED+=("${MODEL_MAP[$num]}")
        else
            warn "Invalid entry: $num -- skipped"
        fi
    done
}

# ─────────────────────────────────────────────────────────────────
#  STEP 8  |  Pull selected models from Ollama registry
# ─────────────────────────────────────────────────────────────────

install_selected_models() {
    section "Downloading Selected Models"

    if [ ${#SELECTED[@]} -eq 0 ]; then
        log "No additional models to download"
        return
    fi

    for model in "${SELECTED[@]}"; do
        if ollama list 2>/dev/null | grep -q "^$model "; then
            log "$model -- already installed"
            SUCCESSFUL_MODELS+=("$model")
        else
            warn "Pulling $model ..."
            if ollama pull "$model"; then
                log "$model -- installed"
                SUCCESSFUL_MODELS+=("$model")
            else
                warn "Failed to pull $model -- skipped"
            fi
        fi
    done
}

# ─────────────────────────────────────────────────────────────────
#  STEP 9  |  Guarantee the fallback model is present
# ─────────────────────────────────────────────────────────────────

install_fallback() {
    section "Fallback Model"

    local fallback="qwen2.5-coder:1.5b"

    if ollama list 2>/dev/null | grep -q "^$fallback "; then
        log "$fallback -- already installed"
    else
        warn "Installing fallback -- $fallback ..."
        ollama pull "$fallback"
        log "$fallback -- installed"
    fi
}

# ─────────────────────────────────────────────────────────────────
#  Build final model list
# ─────────────────────────────────────────────────────────────────

build_final_models() {
    FINAL_MODELS=()

    if [ ${#SUCCESSFUL_MODELS[@]} -gt 0 ]; then
        FINAL_MODELS=("${SUCCESSFUL_MODELS[@]}")
    else
        FINAL_MODELS=("$fallback")
    fi
}

# ─────────────────────────────────────────────────────────────────
#  STEP 10  |  Write the Continue extension configuration
# ─────────────────────────────────────────────────────────────────

set_continue_config() {
    section "Writing Continue Configuration"

    local config_dir="$HOME/.continue"
    mkdir -p "$config_dir"

    local config_file="$config_dir/config.yaml"

    local models_config=()
    for model in "${FINAL_MODELS[@]}"; do
        if [ "$model" = "$fallback" ]; then
            models_config+=("{\"name\": \"$model\", \"provider\": \"ollama\", \"model\": \"$model\", \"roles\": [\"autocomplete\"]}")
        else
            models_config+=("{\"name\": \"$model\", \"provider\": \"ollama\", \"model\": \"$model\", \"roles\": [\"chat\", \"autocomplete\"]}")
        fi
    done

    local models_json
    models_json=$(printf '%s,' "${models_config[@]}" | sed 's/,$//')

    cat > "$config_file" << EOF
{
  "name": "Local AI Config",
  "version": "1.0.0",
  "schema": "v1",
  "models": [$models_json],
  "context": [
    {"provider": "code"},
    {"provider": "docs"},
    {"provider": "diff"},
    {"provider": "terminal"},
    {"provider": "problems"},
    {"provider": "folder"},
    {"provider": "codebase"}
  ],
  "tabAutocomplete": {
    "disable": false
  },
  "slashCommands": [
    {"name": "edit", "description": "Edit selected code"},
    {"name": "comment", "description": "Add comments to code"},
    {"name": "share", "description": "Export conversation"},
    {"name": "cmd", "description": "Generate a shell command"}
  ]
}
EOF

    log "Config written -- $config_file"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 11  |  Launch VSCode in the current directory
# ─────────────────────────────────────────────────────────────────

open_vscode() {
    section "Launching VSCode"
    warn "Opening VSCode..."
    code .
    sleep 2
    log "VSCode launched"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 12  |  Print installation summary
# ─────────────────────────────────────────────────────────────────

show_summary() {
    section "Setup Complete"

    echo -e "  ${BOLD}${WHITE}Configured Models:${RESET}"
    for model in "${FINAL_MODELS[@]}"; do
        if [ "$model" = "$fallback" ]; then
            echo -e "  ${BOLD}${GREEN}  $model${RESET}  ${DIM}[autocomplete]${RESET}"
        else
            echo -e "  ${BOLD}${GREEN}  $model${RESET}  ${DIM}[chat, autocomplete]${RESET}"
        fi
    done

    blank
    echo -e "  ${BOLD}${WHITE}Config File    ${RESET}${DIM}|${RESET}  ${DIM}$HOME/.continue/config.yaml${RESET}"

    echo -e "  ${BOLD}${WHITE}Ollama Status  ${RESET}${DIM}|${RESET}  \c"
    if pgrep -x ollama &>/dev/null; then
        echo -e "${BOLD}${GREEN}Running${RESET}"
    else
        echo -e "${BOLD}${RED}Not Running${RESET}"
    fi

    blank
    echo -e "  ${DIM}Open VSCode -> Continue panel -> Start coding with AI${RESET}"
    blank
}

# ─────────────────────────────────────────────────────────────────
#  STEP 13  |  Open the developer GitHub profile in the browser
# ─────────────────────────────────────────────────────────────────

open_github() {
    local url="https://github.com/moshiurrahmandeap11"

    blank
    echo -e "${BOLD}${CYAN}  ╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║                                                        ║${RESET}"
    echo -e "${BOLD}${CYAN}  ║  ${RESET}${BOLD}${WHITE}Thanks for using Just One Installer                ${RESET}${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║  ${RESET}${BOLD}${WHITE}Developer  :  github.com/moshiurrahmandeap11       ${RESET}${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║                                                        ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚════════════════════════════════════════════════════════╝${RESET}"
    blank

    open "$url"
}

# ─────────────────────────────────────────────────────────────────
#  ENTRY POINT  |  Run all installer steps in sequence
# ─────────────────────────────────────────────────────────────────

# Check for macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "This script is for macOS only"
    exit 1
fi

# Run all steps
print_banner
ensure_homebrew
detect_system
install_ollama
start_ollama
check_vscode
install_continue
fetch_models
show_recommendations
select_models
install_selected_models
if [ ${#SUCCESSFUL_MODELS[@]} -eq 0 ]; then
    install_fallback
fi
build_final_models
set_continue_config
open_vscode
show_summary
open_github

echo -e "  ${DIM}Press any key to exit...${RESET}"
read -n 1