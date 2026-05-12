#!/bin/bash

# ──────────────────────────────────────────────────────────────────
#  AI Smart Installer  |  VSCode + Ollama + Continue  |  v2.0
#  Author : moshiurrahmandeap11
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
    echo "  ║           AI  SMART  INSTALLER   v2.0                  ║"
    echo "  ║       VSCode  +  Ollama  +  Continue  Dev              ║"
    echo "  ║                                                        ║"
    echo "  ╚════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    blank
}

# ─────────────────────────────────────────────────────────────────
#  STEP 1  |  Ensure curl is available
#  Detects the Linux distribution and installs curl via the
#  correct package manager if it is not already present.
# ─────────────────────────────────────────────────────────────────

ensure_curl() {
    section "Checking curl"

    if command -v curl &>/dev/null; then
        log "curl is already installed"
        return
    fi

    warn "curl not found  --  detecting distribution..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        DISTRO=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi

    log "Distribution detected: ${DISTRO}"

    case "$DISTRO" in
        ubuntu|debian|linuxmint|pop|elementary|kali)
            sudo apt-get update -qq && sudo apt-get install -y curl ;;
        fedora)
            sudo dnf install -y curl ;;
        centos|rhel|almalinux|rocky)
            sudo yum install -y curl ;;
        arch|manjaro|endeavouros)
            sudo pacman -Sy --noconfirm curl ;;
        opensuse*|sles)
            sudo zypper install -y curl ;;
        alpine)
            sudo apk add --no-cache curl ;;
        void)
            sudo xbps-install -Sy curl ;;
        *)
            error "Unknown distribution: ${DISTRO}  --  install curl manually"
            exit 1 ;;
    esac

    log "curl installed successfully"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 2  |  Collect system hardware information
#  Reads CPU model and core count, total RAM, GPU name and VRAM.
#  NVIDIA detection uses nvidia-smi; AMD uses rocm-smi.
# ─────────────────────────────────────────────────────────────────

detect_system() {
    section "System Information"

    RAM_GB=$(free -g 2>/dev/null | awk '/Mem:/ {print $2}')
    RAM_MB=$(free -m 2>/dev/null | awk '/Mem:/ {print $2}')
    [ -z "$RAM_GB" ] && RAM_GB=4
    [ -z "$RAM_MB" ] && RAM_MB=4096

    CPU_CORES=$(nproc 2>/dev/null || echo 2)
    CPU_MODEL=$(grep 'model name' /proc/cpuinfo 2>/dev/null \
                | head -1 | cut -d: -f2 | xargs || echo "Unknown CPU")

    GPU_VRAM=0
    GPU_NAME="Not detected"

    if command -v nvidia-smi &>/dev/null; then
        GPU_NAME=$(nvidia-smi --query-gpu=name \
                   --format=csv,noheader 2>/dev/null | head -1 || echo "NVIDIA GPU")
        GPU_VRAM=$(nvidia-smi --query-gpu=memory.total \
                   --format=csv,noheader,nounits 2>/dev/null \
                   | head -1 | awk '{print int($1/1024)}' || echo 0)
    elif command -v rocm-smi &>/dev/null; then
        GPU_NAME="AMD ROCm GPU"
        GPU_VRAM=$(rocm-smi --showmeminfo vram 2>/dev/null \
                   | grep -oP '\d+' | head -1 \
                   | awk '{print int($1/1024)}' || echo 0)
    fi

    DISK_FREE=$(df -BG "$HOME" 2>/dev/null \
                | awk 'NR==2 {gsub("G",""); print $4}' || echo 20)

    echo -e "  ${BOLD}${WHITE}CPU        ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${CPU_MODEL}${RESET}  ${DIM}(${CPU_CORES} cores)${RESET}"
    echo -e "  ${BOLD}${WHITE}RAM        ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${RAM_GB} GB${RESET}  ${DIM}(${RAM_MB} MB)${RESET}"
    echo -e "  ${BOLD}${WHITE}GPU        ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${GPU_NAME}${RESET}"
    echo -e "  ${BOLD}${WHITE}VRAM       ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${GPU_VRAM} GB${RESET}"
    echo -e "  ${BOLD}${WHITE}Disk Free  ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${DISK_FREE} GB${RESET}"
    blank
}

# ─────────────────────────────────────────────────────────────────
#  STEP 3  |  Install and start Ollama
#  Downloads the official install script via curl when Ollama is
#  absent, then launches the inference server in the background.
# ─────────────────────────────────────────────────────────────────

install_ollama() {
    section "Ollama Installation"

    if command -v ollama &>/dev/null; then
        log "Ollama is already installed"
        return
    fi

    warn "Downloading Ollama installer via curl..."
    curl -fsSL https://ollama.com/install.sh | sh
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
    if code --list-extensions 2>/dev/null | grep -q "Continue.continue"; then
        log "Continue extension is already installed"
        return
    fi

    warn "Installing Continue extension..."
    code --install-extension Continue.continue
    log "Continue extension installed"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 5  |  Fetch model list from Ollama library
#  A single curl request scrapes all model slugs from the library
#  page.  If the request fails, a curated built-in list is used.
# ─────────────────────────────────────────────────────────────────

fetch_ollama_models() {
    section "Fetching Ollama Model Library"

    info "Connecting to ollama.com/library..."
    OLLAMA_MODELS=$(curl -s https://ollama.com/library \
                    | grep -oP 'href="/library/\K[^"]+' \
                    | sort -u)

    if [ -z "$OLLAMA_MODELS" ]; then
        warn "Could not reach ollama.com  --  using built-in model list"
        OLLAMA_MODELS="tinyllama phi gemma mistral llama3 codellama deepseek-r1 qwen2.5-coder llava"
    fi

    local count
    count=$(echo "$OLLAMA_MODELS" | wc -l)
    log "${count} models fetched"
}

# ─────────────────────────────────────────────────────────────────
#  MODEL SIZE ESTIMATOR  |  Zero network calls, runs instantly
#
#  Parses the parameter count embedded in the model name
#  (e.g. "7b", "70b", "2.5b") and converts it to an estimated
#  memory footprint using the standard 4-bit quantisation rule:
#
#    size_GB  =  ceil( params_B * 0.55 )    minimum 1 GB
#
#  Models with no numeric size tag default to 3 GB.
# ─────────────────────────────────────────────────────────────────

get_model_size_gb() {
    local model="$1"
    local raw int_part params size

    raw=$(echo "$model" | grep -oiP '[\d]+\.?[\d]*(?=b)' | tail -1)

    if [[ -z "$raw" ]]; then
        echo 3
        return
    fi

    int_part=$(echo "$raw" | cut -d. -f1)
    [ -z "$int_part" ] && int_part=1
    [ "$int_part" -eq 0 ] && int_part=1
    params=$int_part

    # Integer arithmetic: (params * 55 + 99) / 100  =  ceil(params * 0.55)
    size=$(( (params * 55 + 99) / 100 ))
    [ "$size" -lt 1 ] && size=1

    echo "$size"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 6  |  Recommend compatible models based on hardware
#
#  Memory priority:
#    GPU VRAM >= 8 GB  ->  use VRAM  (GPU-accelerated inference)
#    otherwise         ->  use system RAM
#
#  Only models whose estimated size fits within 65 % of the
#  effective memory budget are displayed, preventing OOM crashes.
# ─────────────────────────────────────────────────────────────────

recommend_models() {
    section "Model Recommendation"

    # Choose the most capable memory pool available
    if [ "$GPU_VRAM" -ge 8 ] 2>/dev/null; then
        EFFECTIVE_MEM=$GPU_VRAM
        MEM_SOURCE="GPU VRAM"
    else
        EFFECTIVE_MEM=$RAM_GB
        MEM_SOURCE="System RAM"
    fi

    # 65 % headroom keeps the OS and other processes stable
    MAX_MODEL_SIZE=$(echo "$EFFECTIVE_MEM * 0.65" | bc 2>/dev/null | cut -d. -f1)
    [ -z "$MAX_MODEL_SIZE" ] && MAX_MODEL_SIZE=$(( EFFECTIVE_MEM * 65 / 100 ))
    [ "$MAX_MODEL_SIZE" -lt 1 ] && MAX_MODEL_SIZE=1

    echo -e "  ${BOLD}${WHITE}Memory Source    ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${EFFECTIVE_MEM} GB  (${MEM_SOURCE})${RESET}"
    echo -e "  ${BOLD}${WHITE}Max Model Size   ${RESET}${DIM}|${RESET}  ${BOLD}${YELLOW}${MAX_MODEL_SIZE} GB${RESET}"
    blank

    # The fallback is always installed regardless of user selection
    FALLBACK_MODEL="qwen2.5-coder:1.5b"

    declare -a DISPLAY_NAMES DISPLAY_SIZES DISPLAY_TAGS
    declare -gA MODEL_MAP
    local i=1

    info "Filtering compatible models..."
    blank

    while read -r model; do
        [ -z "$model" ] && continue

        local SIZE
        SIZE=$(get_model_size_gb "$model")

        if [ "$SIZE" -le "$MAX_MODEL_SIZE" ]; then
            # Visual tier label based on footprint
            if   [ "$SIZE" -le 2 ]; then tag="${GREEN}lightweight${RESET}"
            elif [ "$SIZE" -le 6 ]; then tag="${YELLOW}balanced${RESET}"
            else                          tag="${RED}heavy${RESET}"
            fi

            DISPLAY_NAMES[$i]="$model"
            DISPLAY_SIZES[$i]="$SIZE"
            DISPLAY_TAGS[$i]="$tag"
            MODEL_MAP[$i]="$model"
            (( i++ ))
        fi

    done <<< "$OLLAMA_MODELS"

    TOTAL_AVAILABLE=$(( i - 1 ))

    if [ "$TOTAL_AVAILABLE" -eq 0 ]; then
        warn "No models fit within your memory budget  --  only fallback will be used"
    fi

    # Render the selection table
    echo -e "  ${BOLD}${WHITE}$(printf '%-5s  %-32s  %-9s  %s' 'No.' 'Model' 'Size' 'Profile')${RESET}"
    echo -e "  ${DIM}$(printf '%-5s  %-32s  %-9s  %s' '-----' '--------------------------------' '---------' '----------')${RESET}"

    for j in $(seq 1 "$TOTAL_AVAILABLE"); do
        printf "  ${BOLD}${CYAN}%-5s${RESET}  ${BOLD}%-32s${RESET}  ${DIM}%-9s${RESET}  " \
            "${j})" "${DISPLAY_NAMES[$j]}" "~${DISPLAY_SIZES[$j]} GB"
        echo -e "${BOLD}${DISPLAY_TAGS[$j]}"
    done

    blank
    echo -e "  ${BOLD}${WHITE}Default Fallback   ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${FALLBACK_MODEL}${RESET}  ${DIM}(autocomplete only)${RESET}"
    blank

    # List models already present in the local Ollama registry
    echo -e "  ${BOLD}${WHITE}Already Installed:${RESET}"
    local installed
    installed=$(ollama list 2>/dev/null | awk 'NR>1 {print "    " $1}' || true)
    if [ -z "$installed" ]; then
        echo -e "  ${DIM}    None${RESET}"
    else
        echo -e "${BOLD}${GREEN}${installed}${RESET}"
    fi
    blank
}

# ─────────────────────────────────────────────────────────────────
#  STEP 7  |  Interactive model selection
#  The user enters comma-separated row numbers from the table.
#  Pressing Enter without input activates fallback-only mode.
# ─────────────────────────────────────────────────────────────────

select_models() {
    echo -e "  ${BOLD}${WHITE}Select models to install:${RESET}"
    echo -e "  ${DIM}Enter row numbers separated by commas  (example:  1,3,5)${RESET}"
    echo -e "  ${DIM}Press Enter to skip and use the fallback model only${RESET}"
    blank
    echo -ne "  ${BOLD}${CYAN}Your choice:  ${RESET}"
    read -r input

    SELECTED=()

    if [[ -z "$input" || "$input" == "0" ]]; then
        log "No selection  --  fallback model will be used"
        return
    fi

    IFS=',' read -ra arr <<< "$input"
    for x in "${arr[@]}"; do
        x=$(echo "$x" | xargs)
        if [[ -n "${MODEL_MAP[$x]}" ]]; then
            SELECTED+=("${MODEL_MAP[$x]}")
        else
            warn "Invalid entry: ${x}  --  skipped"
        fi
    done
}

# ─────────────────────────────────────────────────────────────────
#  STEP 8  |  Pull selected models from Ollama registry
#  Models already present in the local store are skipped.
# ─────────────────────────────────────────────────────────────────

install_models() {
    section "Downloading Selected Models"

    if [ "${#SELECTED[@]}" -eq 0 ]; then
        log "No additional models to download"
        return
    fi

    for m in "${SELECTED[@]}"; do
        if ollama list 2>/dev/null | grep -q "^${m}"; then
            log "${m}  --  already installed"
        else
            warn "Pulling  ${m} ..."
            ollama pull "$m"
            log "${m}  --  installed"
        fi
    done
}

# ─────────────────────────────────────────────────────────────────
#  STEP 9  |  Guarantee the fallback model is present
#  qwen2.5-coder:1.5b is always available so that tab-autocomplete
#  works even when the user selects no additional models.
# ─────────────────────────────────────────────────────────────────

ensure_fallback() {
    section "Fallback Model"

    [ -z "$FALLBACK_MODEL" ] && FALLBACK_MODEL="qwen2.5-coder:1.5b"

    if ollama list 2>/dev/null | grep -q "^${FALLBACK_MODEL}"; then
        log "${FALLBACK_MODEL}  --  already installed"
    else
        warn "Installing fallback  --  ${FALLBACK_MODEL} ..."
        ollama pull "$FALLBACK_MODEL"
        log "${FALLBACK_MODEL}  --  installed"
    fi
}

# ─────────────────────────────────────────────────────────────────
#  Assemble the final ordered model list for config generation.
#  Selected models appear first; the fallback is always last.
# ─────────────────────────────────────────────────────────────────

build_final_models() {
    FINAL_MODELS=()
    [ "${#SELECTED[@]}" -gt 0 ] && FINAL_MODELS=("${SELECTED[@]}")

    local found=0
    for m in "${FINAL_MODELS[@]}"; do
        [ "$m" == "$FALLBACK_MODEL" ] && found=1
    done
    [ "$found" -eq 0 ] && FINAL_MODELS+=("$FALLBACK_MODEL")
}

# ─────────────────────────────────────────────────────────────────
#  STEP 10  |  Write the Continue extension configuration
#
#  Role assignment strategy:
#    fallback model   ->  roles: [autocomplete]          (small, fast)
#    all other models ->  roles: [chat, autocomplete]    (full capability)
# ─────────────────────────────────────────────────────────────────

setup_continue() {
    section "Writing Continue Configuration"

    mkdir -p ~/.continue

    cat > ~/.continue/config.yaml <<EOF
name: Local AI Config
version: 1.0.0
schema: v1

models:
EOF

    for m in "${FINAL_MODELS[@]}"; do
        if [ "$m" == "$FALLBACK_MODEL" ]; then
cat >> ~/.continue/config.yaml <<EOF
  - name: $m
    provider: ollama
    model: $m
    roles: [autocomplete]
EOF
        else
cat >> ~/.continue/config.yaml <<EOF
  - name: $m
    provider: ollama
    model: $m
    roles: [chat, autocomplete]
EOF
        fi
    done

cat >> ~/.continue/config.yaml <<EOF

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
EOF

    log "Config written  --  ~/.continue/config.yaml"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 11  |  Launch VSCode in the current directory
# ─────────────────────────────────────────────────────────────────

open_vscode() {
    section "Launching VSCode"
    warn "Opening VSCode..."
    code . &
    sleep 2
    log "VSCode launched"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 12  |  Print installation summary
# ─────────────────────────────────────────────────────────────────

print_summary() {
    section "Setup Complete"

    echo -e "  ${BOLD}${WHITE}Configured Models:${RESET}"
    for m in "${FINAL_MODELS[@]}"; do
        if [ "$m" == "$FALLBACK_MODEL" ]; then
            echo -e "  ${BOLD}${GREEN}  ${m}${RESET}  ${DIM}[autocomplete]${RESET}"
        else
            echo -e "  ${BOLD}${GREEN}  ${m}${RESET}  ${DIM}[chat, autocomplete]${RESET}"
        fi
    done

    blank
    echo -e "  ${BOLD}${WHITE}Config File    ${RESET}${DIM}|${RESET}  ${DIM}~/.continue/config.yaml${RESET}"
    echo -e "  ${BOLD}${WHITE}Ollama Status  ${RESET}${DIM}|${RESET}  $(pgrep -x ollama &>/dev/null \
              && echo -e "${BOLD}${GREEN}Running${RESET}" \
              || echo -e "${BOLD}${RED}Not Running${RESET}")"
    blank
    echo -e "  ${BOLD}${YELLOW}Open VSCode  ->  Continue panel  ->  Start coding with AI${RESET}"
    blank
}

# ─────────────────────────────────────────────────────────────────
#  STEP 13  |  Open the developer GitHub profile in the browser
#  xdg-open is the standard Linux browser launcher.
#  Falls back gracefully if no launcher is found.
# ─────────────────────────────────────────────────────────────────

open_github() {
    local url="https://github.com/moshiurrahmandeap11"

    blank
    echo -e "${BOLD}${CYAN}  ╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║                                                        ║${RESET}"
    echo -e "${BOLD}${CYAN}  ║  ${WHITE}  Thanks for using AI Smart Installer                ${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║  ${WHITE}  Developer  :  github.com/moshiurrahmandeap11       ${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║                                                        ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚════════════════════════════════════════════════════════╝${RESET}"
    blank

    if command -v xdg-open &>/dev/null; then
        xdg-open "$url" 2>/dev/null &
    elif command -v open &>/dev/null; then
        open "$url" 2>/dev/null &
    else
        warn "No browser launcher found  --  visit manually:  ${url}"
    fi
}

# ─────────────────────────────────────────────────────────────────
#  ENTRY POINT  |  Run all installer steps in sequence
# ─────────────────────────────────────────────────────────────────

# all installer steps in sequence

print_banner

ensure_curl
detect_system
install_ollama
start_ollama
check_vscode
install_continue
fetch_ollama_models
recommend_models
select_models
install_models
ensure_fallback
build_final_models
setup_continue
open_vscode
print_summary
open_github