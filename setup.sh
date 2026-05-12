#!/bin/bash

# ==============================================
# Ollama + Continue + VSCode Automation
# Dynamic Model Selector Based on Hardware
# Now displays already installed models
# Developed by Moshiur Rahman
# ==============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Helper Functions
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
highlight() { echo -e "${CYAN}${BOLD}$1${NC}"; }
divider() { echo "=========================================="; }

# Detect Available System Memory (in GB)
detect_ram_gb() {
    if command -v free &> /dev/null; then
        FREE_RAM_GB=$(free -g | awk '/^Mem:/ {print $2}')
        echo "$FREE_RAM_GB"
    elif command -v sysctl &> /dev/null; then
        FREE_RAM_GB=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
        echo "$FREE_RAM_GB"
    else
        echo "4"
    fi
}

# Detect GPU Type
detect_gpu() {
    if command -v nvidia-smi &> /dev/null; then
        echo "nvidia"
    elif command -v rocminfo &> /dev/null; then
        echo "amd"
    elif [[ "$(uname)" == "Darwin" ]] && sysctl -n machdep.cpu.brand_string | grep -qi "Apple"; then
        echo "apple-silicon"
    else
        echo "none"
    fi
}

# Determine System Tier
get_system_tier() {
    local ram="$1"
    local gpu="$2"
    if [[ "$gpu" == "nvidia" || "$gpu" == "amd" || "$gpu" == "apple-silicon" ]] && [[ "$ram" -ge 16 ]]; then
        echo "performance"
    elif [[ "$ram" -ge 16 ]]; then
        echo "balanced"
    elif [[ "$ram" -le 8 ]]; then
        echo "light"
    else
        echo "light"
    fi
}

# Install curl if missing
install_curl() {
    if command -v curl &> /dev/null; then return; fi
    warn "curl not found. Installing..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y curl
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy --noconfirm curl
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y curl
    else
        error "No supported package manager found."
        exit 1
    fi
    log "curl installed."
}

# Install Ollama
install_ollama() {
    if command -v ollama &> /dev/null; then return; fi
    warn "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    log "Ollama installed."
}

# Start Ollama Server
start_ollama() {
    if pgrep -x "ollama" > /dev/null; then return; fi
    warn "Starting Ollama server..."
    ollama serve > /dev/null 2>&1 &
    sleep 5
    log "Ollama server started."
}

# List already installed models
show_installed_models() {
    local installed
    installed=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}')
    if [[ -z "$installed" ]]; then
        warn "No models currently installed."
        echo ""
        return
    fi
    divider
    highlight "ALREADY INSTALLED MODELS"
    echo "$installed" | while read -r model; do
        echo "  ✅ $model"
    done
    divider
    echo ""
}

# Check VSCode
check_vscode() {
    if ! command -v code &> /dev/null; then
        error "VSCode CLI not found. Install 'code' command in PATH."
        exit 1
    fi
    log "VSCode CLI detected."
}

# Install Continue Extension
install_continue_extension() {
    if code --list-extensions | grep -q "Continue.continue"; then return; fi
    warn "Installing Continue extension..."
    code --install-extension Continue.continue
    log "Continue extension installed."
}

# Backup Existing Config
backup_continue_config() {
    mkdir -p ~/.continue
    if [ -f ~/.continue/config.yaml ]; then
        cp ~/.continue/config.yaml ~/.continue/config.backup.$(date +%s).yaml
        log "Old config backed up."
    fi
}

# Write Continue Config
write_continue_config() {
    local models_yaml=""
    for model_entry in "${SELECTED_MODELS[@]}"; do
        IFS=":" read -r name provider model_label <<< "$model_entry"
        models_yaml+="  - name: ${name}\n    provider: ${provider}\n    model: ${model_label}\n    roles: [chat, edit, apply, autocomplete]\n    systemPrompt: \"You are a professional AI coding assistant.\"\n"
    done

    cat > ~/.continue/config.yaml <<EOF
name: Local Dynamic Config
version: 1.0.0
schema: v1

models:
$(echo -e "$models_yaml")

context:
  - provider: code
  - provider: docs
  - provider: diff
  - provider: terminal
  - provider: problems
  - provider: folder
  - provider: codebase
EOF
    log "Continue config written with selected models."
}

# Open VSCode
open_vscode() {
    warn "Opening VSCode..."
    code .
    sleep 3
}

# Display Available Models and Let User Choose
select_models_interactive() {
    local tier="$1"
    local ram="$2"
    local gpu="$3"

    echo ""
    highlight "SYSTEM ANALYSIS"
    echo "RAM: ${ram}GB | GPU: ${gpu} | Profile: ${tier}"
    divider
    echo ""

    # Show installed models first
    show_installed_models

    # Define model catalog: name|ollama_label|min_ram_gb|gpu_required|tier_match
    declare -A MODEL_LIST
    MODEL_LIST["tinyllama (1.1B)"]="tinyllama:latest|4|none|light"
    MODEL_LIST["phi3:mini (3.8B)"]="phi3:mini|6|none|light"
    MODEL_LIST["gemma2:2b"]="gemma2:2b|6|none|light"
    MODEL_LIST["mistral (7B)"]="mistral:latest|8|none|balanced"
    MODEL_LIST["llama3.1:8b"]="llama3.1:8b|10|none|balanced"
    MODEL_LIST["neural-chat (7B)"]="neural-chat:latest|8|none|balanced"
    MODEL_LIST["codellama:7b"]="codellama:7b|8|none|balanced"
    MODEL_LIST["deepseek-coder:6.7b"]="deepseek-coder:6.7b|8|none|balanced"
    MODEL_LIST["llama3.1:70b"]="llama3.1:70b|32|nvidia|performance"
    MODEL_LIST["codellama:34b"]="codellama:34b|24|nvidia|performance"
    MODEL_LIST["deepseek-coder:33b"]="deepseek-coder:33b|24|nvidia|performance"
    MODEL_LIST["mixtral:8x7b"]="mixtral:8x7b|32|nvidia|performance"
    MODEL_LIST["phi3:medium"]="phi3:medium|16|nvidia|performance"

    local available=()
    local recommended=()

    for display_name in "${!MODEL_LIST[@]}"; do
        IFS="|" read -r label min_ram req_gpu tier_match <<< "${MODEL_LIST[$display_name]}"
        [[ "$ram" -lt "$min_ram" ]] && continue
        [[ "$tier_match" == "performance" && "$gpu" == "none" ]] && continue
        case "$tier" in
            light) [[ "$tier_match" == "balanced" || "$tier_match" == "performance" ]] && continue ;;
            balanced) [[ "$tier_match" == "performance" ]] && continue ;;
        esac
        available+=("$display_name|$label")
        [[ "$tier_match" == "$tier" ]] && recommended+=("$display_name")
    done

    if [[ ${#available[@]} -eq 0 ]]; then
        warn "No additional models available for your hardware."
        exit 1
    fi

    echo "Available Models to Install (Select by number, comma separated):"
    divider
    local count=1
    for entry in "${available[@]}"; do
        IFS="|" read -r disp label <<< "$entry"
        local tag=""
        for rec in "${recommended[@]}"; do
            [[ "$rec" == "$disp" ]] && tag=" ${GREEN}[RECOMMENDED]${NC}" && break
        done
        echo -e "  ${BOLD}$count)${NC} ${disp}${tag}"
        ((count++))
    done
    divider
    echo -n "Your choice(s): "
    read user_choice

    IFS=',' read -ra choices <<< "$user_choice"
    SELECTED_MODELS=()
    for c in "${choices[@]}"; do
        c=$(echo "$c" | xargs)
        if [[ "$c" =~ ^[0-9]+$ ]] && [[ "$c" -ge 1 && "$c" -le "${#available[@]}" ]]; then
            idx=$((c-1))
            IFS="|" read -r disp label <<< "${available[$idx]}"
            SELECTED_MODELS+=("${disp}:ollama:${label}")
        else
            warn "Invalid choice ignored: $c"
        fi
    done

    if [[ ${#SELECTED_MODELS[@]} -eq 0 ]]; then
        error "No valid model selected. Exiting."
        exit 1
    fi

    echo ""
    highlight "You have selected:"
    for model_entry in "${SELECTED_MODELS[@]}"; do
        IFS=":" read -r name _ _ <<< "$model_entry"
        echo "  - $name"
    done
    echo ""
}

# Pull selected models
pull_selected_models() {
    for model_entry in "${SELECTED_MODELS[@]}"; do
        IFS=":" read -r _ _ label <<< "$model_entry"
        if ollama list | grep -q "${label%%:*}" ; then
            log "Model ${label} already installed."
            continue
        fi
        warn "Pulling model: ${label} ..."
        ollama pull "$label"
        log "Model ${label} installed."
    done
}

# ====================== MAIN ======================
echo ""
divider
echo "      AI Bootstrap Installer "
echo "      Developed By Moshiur "
echo "      GitHub: https://github.com/moshiurrahmandeap11"
echo "      Web: https://moshiurrahman.online"
divider
echo ""

RAM_GB=$(detect_ram_gb)
GPU=$(detect_gpu)
TIER=$(get_system_tier "$RAM_GB" "$GPU")

install_curl
install_ollama
start_ollama

select_models_interactive "$TIER" "$RAM_GB" "$GPU"

pull_selected_models

check_vscode
install_continue_extension
backup_continue_config
write_continue_config

# Open GitHub
xdg-open "https://github.com/moshiurrahmandeap11" 2>/dev/null || \
    open "https://github.com/moshiurrahmandeap11" 2>/dev/null || true

open_vscode

echo ""
divider
echo " Setup Complete "
echo " Local AI is ready in VSCode."
echo " Follow Developer on GitHub"
divider
echo ""