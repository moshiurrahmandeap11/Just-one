#!/bin/bash

# ──────────────────────────────────────────────────────────────────
#  Just One  |  Local AI Automator  |  v2.5
#  macOS Version
#  Author : Moshiur Rahman Deap
#  Github : https://github.com/moshiurrahmandeap11
#  Contact: https://linkedin.com/in/moshiurrahmandeap
#  License: MIT
# ──────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
    clear || true
fi
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

# Safe TTY input reader (works even when piped via `curl ... | bash`)
read_tty() {
    local _var_name="$1"
    local _val=""
    if [ -r /dev/tty ]; then
        IFS= read -r _val < /dev/tty || _val=""
    elif [ -t 0 ]; then
        IFS= read -r _val || _val=""
    fi
    eval "$_var_name=\$_val"
}

# ── Section Header ────────────────────────────────────────────────
section() {
    local title="$1"
    local width=56
    local line
    line=$(printf '═%.0s' $(seq 1 $width))
    local inner=$(( width - 2 ))
    local pad=$(( (inner - ${#title}) / 2 ))
    [ "$pad" -lt 0 ] && pad=0
    local rpad=$(( inner - ${#title} - pad ))
    [ "$rpad" -lt 0 ] && rpad=0
    local spaces_l="" spaces_r=""
    [ "$pad" -gt 0 ] && spaces_l=$(printf '%*s' "$pad" '')
    [ "$rpad" -gt 0 ] && spaces_r=$(printf '%*s' "$rpad" '')

    blank
    echo -e "${BOLD}${CYAN}  ╔${line}╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║${spaces_l}${WHITE}${title}${CYAN}${spaces_r}║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚${line}╝${RESET}"
    blank
}

# ── Banner ────────────────────────────────────────────────────────
print_banner() {
    echo -e "${BOLD}${CYAN}"
    echo "  ╔════════════════════════════════════════════════════════╗"
    echo "  ║                                                        ║"
    echo "  ║           Just One Installer     v2.5                  ║"
    echo "  ║       Zero-Config Local AI & Codebase RAG              ║"
    echo "  ║       Developed By Moshiur Rahman Deap                 ║"
    echo "  ║                                                        ║"
    echo "  ╚════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    blank
}

# ── Global Defaults ───────────────────────────────────────────────
FALLBACK_MODEL="qwen2.5-coder:1.5b"
EMBEDDING_MODEL="nomic-embed-text"
SELECTED=()
SUCCESSFUL_MODELS=()
FINAL_MODELS=()
MODEL_MAP=()
EDITOR_FOUND=false

# ─────────────────────────────────────────────────────────────────
#  STEP 1  |  Ensure Homebrew is available
# ─────────────────────────────────────────────────────────────────

ensure_homebrew() {
    section "Checking Homebrew"

    if [ -x "/opt/homebrew/bin/brew" ] && ! command -v brew &>/dev/null; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ] && ! command -v brew &>/dev/null; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if command -v brew &>/dev/null; then
        log "Homebrew is already installed"
        return
    fi

    warn "Homebrew not found -- installing..."
    info "This requires administrator privileges"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    log "Homebrew installed successfully"
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

# ─────────────────────────────────────────────────────────────────
#  STEP 2  |  Collect system hardware information
# ─────────────────────────────────────────────────────────────────

detect_system() {
    section "System Information"

    CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
    CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m)

    RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 8589934592)
    RAM_MB=$(( RAM_BYTES / 1024 / 1024 ))
    RAM_GB=$(( RAM_MB / 1024 ))
    [ "$RAM_GB" -lt 1 ] && RAM_GB=8

    GPU_NAME="Apple Metal / Unified Memory"
    if system_profiler SPDisplaysDataType 2>/dev/null | grep -q "Chipset Model"; then
        GPU_NAME=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | cut -d: -f2 | xargs || echo "Apple GPU")
    fi

    # macOS portable disk space check
    DISK_FREE=$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2 {printf "%d", $4 / 1024 / 1024}' || true)
    [ -z "$DISK_FREE" ] && DISK_FREE="N/A"

    echo -e "  ${BOLD}${WHITE}CPU        ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${CPU_MODEL}${RESET}  ${DIM}(${CPU_CORES} cores)${RESET}"
    echo -e "  ${BOLD}${WHITE}RAM        ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${RAM_GB} GB${RESET}  ${DIM}(${RAM_MB} MB)${RESET}"
    echo -e "  ${BOLD}${WHITE}GPU        ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${GPU_NAME}${RESET}"
    echo -e "  ${BOLD}${WHITE}Disk Free  ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${DISK_FREE} GB${RESET}"
    blank

    # On Apple Silicon / macOS, Unified Memory allows efficient shared memory
    EFFECTIVE_MEM=$RAM_GB
    MEM_SOURCE="Unified Memory"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 3  |  Install and start Ollama
# ─────────────────────────────────────────────────────────────────

ollama_ready() {
    curl -fsS --max-time 2 "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1
}

install_ollama() {
    section "Ollama Installation"

    if command -v ollama &>/dev/null; then
        log "Ollama is already installed"
        return
    fi

    warn "Installing Ollama via Homebrew..."
    if brew install ollama; then
        log "Ollama installed successfully"
    else
        error "Ollama installation failed."
        exit 1
    fi
}

start_ollama() {
    export OLLAMA_FLASH_ATTENTION=1
    export OLLAMA_KEEP_ALIVE="24h"
    if command -v launchctl &>/dev/null; then
        launchctl setenv OLLAMA_FLASH_ATTENTION "1" 2>/dev/null || true
        launchctl setenv OLLAMA_KEEP_ALIVE "24h" 2>/dev/null || true
    fi

    if ollama_ready; then
        log "Ollama server is already running (Flash Attention + 24h Keep-Alive)"
        return
    fi

    if ! pgrep -x ollama &>/dev/null; then
        warn "Starting Ollama background server..."
        nohup ollama serve > /dev/null 2>&1 &
    fi

    local attempt=0
    while [ "$attempt" -lt 15 ]; do
        if ollama_ready; then
            log "Ollama server is ready (Flash Attention + 24h Keep-Alive)"
            return
        fi
        sleep 1
        attempt=$(( attempt + 1 ))
    done

    warn "Ollama server started, API may still be warming up."
}

# ─────────────────────────────────────────────────────────────────
#  STEP 4  |  Multi-Editor Detection & Continue Extension
# ─────────────────────────────────────────────────────────────────

detect_editor() {
    section "Checking AI Code Editor"

    if command -v code &>/dev/null; then
        EDITOR_NAME="VS Code"
        EDITOR_CMD="code"
        EDITOR_FOUND=true
        log "${EDITOR_NAME} CLI detected (${EDITOR_CMD})"
    elif command -v cursor &>/dev/null; then
        EDITOR_NAME="Cursor"
        EDITOR_CMD="cursor"
        EDITOR_FOUND=true
        log "${EDITOR_NAME} CLI detected (${EDITOR_CMD})"
    elif command -v code-insiders &>/dev/null; then
        EDITOR_NAME="VS Code Insiders"
        EDITOR_CMD="code-insiders"
        EDITOR_FOUND=true
        log "${EDITOR_NAME} CLI detected (${EDITOR_CMD})"
    elif command -v codium &>/dev/null; then
        EDITOR_NAME="VSCodium"
        EDITOR_CMD="codium"
        EDITOR_FOUND=true
        log "${EDITOR_NAME} CLI detected (${EDITOR_CMD})"
    else
        EDITOR_NAME="Not detected (VS Code/Cursor)"
        EDITOR_CMD="code"
        EDITOR_FOUND=false
        warn "No supported code editor CLI found on PATH (checked code, cursor, code-insiders, codium)."
        info "Please install VS Code from https://code.visualstudio.com"
    fi
}

install_continue() {
    if [ "$EDITOR_FOUND" != true ]; then
        warn "Skipping auto-extension install. You can install Continue manually in your editor."
        return
    fi

    local extensions
    extensions=$("$EDITOR_CMD" --list-extensions 2>/dev/null || true)
    if echo "$extensions" | grep -q "Continue.continue"; then
        log "Continue extension is already installed in ${EDITOR_NAME}"
        return
    fi

    warn "Installing Continue extension in ${EDITOR_NAME}..."
    if "$EDITOR_CMD" --install-extension Continue.continue; then
        log "Continue extension installed"
    else
        warn "Could not auto-install Continue extension. You can install it manually inside ${EDITOR_NAME}."
    fi
}

# ─────────────────────────────────────────────────────────────────
#  STEP 5  |  Fetch model list from Ollama library
# ─────────────────────────────────────────────────────────────────

fetch_models() {
    section "Fetching Ollama Model Library"
    info "Connecting to ollama.com/library..."

    local raw_html
    raw_html=$(curl -s --max-time 8 "https://ollama.com/library" 2>/dev/null || true)

    # POSIX compliant extraction for BSD macOS grep/sed
    local models
    models=$(echo "$raw_html" | sed -n 's/.*href="\/library\/\([a-zA-Z0-9_.:-]*\)".*/\1/p' | sort -u)

    if [ -z "$models" ]; then
        warn "Could not reach ollama.com -- using built-in model list"
        OLLAMA_MODELS=(
            "deepseek-r1" "qwen2.5-coder" "llama3.2" "llama3.1" "mistral"
            "codellama" "phi4" "gemma2" "llava"
        )
    else
        OLLAMA_MODELS=()
        while IFS= read -r line; do
            [ -n "$line" ] && OLLAMA_MODELS+=("$line")
        done <<< "$models"
    fi

    log "Loaded ${#OLLAMA_MODELS[@]} model families"
}

get_model_size_gb() {
    local model="$1"
    local est
    est=$(printf '%s\n' "$model" | awk '{
        s = tolower($0)
        last = ""
        while (match(s, /[0-9]+(\.[0-9]+)?b([^a-z0-9]|$)/)) {
            tok = substr(s, RSTART, RLENGTH)
            sub(/b.*/, "", tok)
            last = tok
            s = substr(s, RSTART + RLENGTH)
        }
        if (last != "") {
            val = int((last * 0.55) + 0.999999)
            if (val < 1) val = 1
            print val
        }
    }')

    if [ -n "$est" ]; then
        echo "$est"
        return
    fi

    case "$model" in
        *qwq*)                                                                   echo 18 ;;
        *phi4*)                                                                  echo 9 ;;
        *gemma2*)                                                                echo 6 ;;
        *llama3.2*)                                                              echo 2 ;;
        *llama3.1*|*llama3.3*|*mistral*|*codellama*|*llava*|*coder*|*deepseek*)  echo 5 ;;
        *)                                                                       echo 4 ;;
    esac
}

get_model_tag() {
    local model="$1"
    case "$model" in
        *coder*|*code*|*starcoder*)    echo "Coder" ;;
        *deepseek-r1*|*qwq*)          echo "Reasoning" ;;
        *llava*|*vision*|*minicpm-v*) echo "Vision" ;;
        *)                            echo "General" ;;
    esac
}

# ─────────────────────────────────────────────────────────────────
#  STEP 6  |  Selection: Quick Preset vs Custom
# ─────────────────────────────────────────────────────────────────

select_mode_and_models() {
    section "Model Setup Mode"

    local max_model_size=$(( (EFFECTIVE_MEM * 65) / 100 ))
    [ "$max_model_size" -lt 1 ] && max_model_size=1

    echo -e "  ${BOLD}${WHITE}Memory Source    ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${EFFECTIVE_MEM} GB (${MEM_SOURCE})${RESET}"
    echo -e "  ${BOLD}${WHITE}Max Model Budget ${RESET}${DIM}|${RESET}  ${BOLD}${YELLOW}${max_model_size} GB (Safe 65% limit)${RESET}"
    blank

    echo -e "  ${BOLD}${WHITE}Choose your setup preference:${RESET}"
    blank
    echo -e "  ${BOLD}${CYAN}[1] ⚡ Quick Recommended Setup (1-Click)${RESET}"
    echo -e "      ${DIM}Auto-configures best Chat/Coding model + Fast Autocomplete + Codebase RAG${RESET}"
    blank
    echo -e "  ${BOLD}${YELLOW}[2] 🛠️  Custom Model Selection${RESET}"
    echo -e "      ${DIM}Browse dynamic table and pick individual models by number${RESET}"
    blank

    echo -e "  ${BOLD}${WHITE}Your choice [1/2, default: 1]: ${RESET}\c"
    read_tty mode_choice
    mode_choice=$(echo "$mode_choice" | xargs)

    if [ -z "$mode_choice" ] || [ "$mode_choice" = "1" ]; then
        blank
        log "Applying Quick Recommended Preset for ${EFFECTIVE_MEM} GB Unified Memory..."
        if [ "$EFFECTIVE_MEM" -ge 24 ]; then
            SELECTED=("qwen2.5-coder:14b" "deepseek-r1:8b")
        elif [ "$EFFECTIVE_MEM" -ge 12 ]; then
            SELECTED=("qwen2.5-coder:7b" "deepseek-r1:7b")
        elif [ "$EFFECTIVE_MEM" -ge 8 ]; then
            SELECTED=("qwen2.5-coder:7b")
        else
            SELECTED=("qwen2.5-coder:3b")
        fi
        info "Auto-selected models: ${SELECTED[*]}"
        return
    fi

    # Custom Table Selection
    section "Available Models"
    printf "  ${BOLD}${WHITE}%-4s  %-28s  %-9s  %s${RESET}\n" "No." "Model" "Size" "Category"
    printf "  ${DIM}%-4s  %-28s  %-9s  %s${RESET}\n" "----" "----------------------------" "---------" "--------"

    local num=1
    MODEL_MAP=()
    for model in "${OLLAMA_MODELS[@]}"; do
        local size
        size=$(get_model_size_gb "$model")
        if [ "$size" -le "$max_model_size" ]; then
            local tag
            tag=$(get_model_tag "$model")
            MODEL_MAP[$num]="$model"
            printf "  ${BOLD}${CYAN}%2d)${RESET}  %-28s  ~%-7s  ${YELLOW}[%s]${RESET}\n" "$num" "$model" "${size} GB" "$tag"
            num=$(( num + 1 ))
        fi
    done

    blank
    echo -e "  ${DIM}Select models by entering row numbers separated by commas (e.g. 1,3)${RESET}"
    echo -e "  ${DIM}Press Enter to skip manual models and use the default coder fallback.${RESET}"
    blank
    echo -e "  ${BOLD}${CYAN}Your choice: ${RESET}\c"
    read_tty input
    input=$(echo "$input" | xargs)

    if [ -n "$input" ] && [ "$input" != "0" ]; then
        IFS=',' read -ra numbers <<< "$input"
        for n in "${numbers[@]}"; do
            n=$(echo "$n" | xargs)
            [ -z "$n" ] && continue
            if [[ "$n" =~ ^[0-9]+$ ]] && [ -n "${MODEL_MAP[$n]}" ]; then
                local chosen="${MODEL_MAP[$n]}"
                local already=false
                for existing in "${SELECTED[@]}"; do
                    [ "$existing" = "$chosen" ] && already=true && break
                done
                [ "$already" = false ] && SELECTED+=("$chosen")
            else
                warn "Invalid entry: $n -- skipped"
            fi
        done
    fi
}

# ─────────────────────────────────────────────────────────────────
#  STEP 7  |  Install All Models (Selected + Fallback + Embedding)
# ─────────────────────────────────────────────────────────────────

is_model_installed() {
    local model="$1"
    local target="$model"
    if [[ "$model" != *:* ]]; then
        target="${model}:latest"
    fi
    ollama list 2>/dev/null | awk -v m="$model" -v t="$target" 'NR>1 && ($1 == t || $1 == m) {found=1; exit} END{exit !found}'
}

install_all_models() {
    section "Downloading AI Models"

    if ! command -v ollama &>/dev/null; then
        error "Ollama command not found. Please restart your terminal and run again."
        exit 1
    fi

    # 1. Pull Selected Models
    if [ ${#SELECTED[@]} -gt 0 ]; then
        for model in "${SELECTED[@]}"; do
            if is_model_installed "$model"; then
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
    fi

    # 2. Guarantee Tab-Autocomplete Fallback Model
    blank
    info "Checking Tab-Autocomplete model (${FALLBACK_MODEL})..."
    if is_model_installed "${FALLBACK_MODEL}"; then
        log "${FALLBACK_MODEL} -- already installed"
    else
        warn "Installing tab-autocomplete fallback -- ${FALLBACK_MODEL} ..."
        if ollama pull "${FALLBACK_MODEL}"; then
            log "${FALLBACK_MODEL} -- installed"
        else
            warn "Could not pull ${FALLBACK_MODEL}"
        fi
    fi

    # 3. Pull Codebase Embedding Model
    blank
    info "Checking Codebase RAG Embedding model (${EMBEDDING_MODEL})..."
    if is_model_installed "${EMBEDDING_MODEL}"; then
        log "${EMBEDDING_MODEL} -- already installed"
    else
        warn "Installing codebase embedding model -- ${EMBEDDING_MODEL} (274 MB) ..."
        if ollama pull "${EMBEDDING_MODEL}"; then
            log "${EMBEDDING_MODEL} -- installed"
        else
            warn "Could not pull ${EMBEDDING_MODEL}. Codebase indexing may need manual setup."
        fi
    fi

    # Build final list
    FINAL_MODELS=()
    if [ ${#SUCCESSFUL_MODELS[@]} -gt 0 ]; then
        FINAL_MODELS=("${SUCCESSFUL_MODELS[@]}")
    else
        FINAL_MODELS=("$FALLBACK_MODEL")
    fi
}

# ─────────────────────────────────────────────────────────────────
#  STEP 8  |  Write Continue Configuration & Rules (Pure YAML v1)
# ─────────────────────────────────────────────────────────────────

set_continue_config() {
    section "Writing Continue Configuration"

    local config_dir="$HOME/.continue"
    mkdir -p "$config_dir"
    local config_file="$config_dir/config.yaml"
    local rules_file="$config_dir/.continuerules"

    cat > "$config_file" << EOF
name: Local AI Config
version: 1.0.0
schema: v1

models:
EOF

    local has_fallback=false
    for model in "${FINAL_MODELS[@]}"; do
        if [ "$model" = "$FALLBACK_MODEL" ]; then
            has_fallback=true
            cat >> "$config_file" << EOF
  - name: $model
    provider: ollama
    model: $model
    roles:
      - chat
      - edit
      - apply
      - autocomplete

EOF
        else
            cat >> "$config_file" << EOF
  - name: $model
    provider: ollama
    model: $model
    roles:
      - chat
      - edit
      - apply

EOF
        fi
    done

    if [ "$has_fallback" = false ]; then
        cat >> "$config_file" << EOF
  - name: $FALLBACK_MODEL
    provider: ollama
    model: $FALLBACK_MODEL
    roles:
      - autocomplete

EOF
    fi

    cat >> "$config_file" << EOF
  - name: $EMBEDDING_MODEL
    provider: ollama
    model: $EMBEDDING_MODEL
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
EOF

    log "Config written -- $config_file"

    cat > "$rules_file" << 'EOF'
# Local AI Development Rules
- Write clean, modular, modern, and well-typed code.
- Always include error handling and handle edge cases gracefully.
- Follow idioms and conventions of the target programming language.
- Do not leave unfinished placeholder comments like '// TODO' without implementation.
EOF
    log "Developer rules written -- $rules_file"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 9  |  Launch Editor & Summary
# ─────────────────────────────────────────────────────────────────

open_editor() {
    section "Launching Editor"
    if [ "$EDITOR_FOUND" = true ]; then
        warn "Opening ${EDITOR_NAME}..."
        "$EDITOR_CMD" . >/dev/null 2>&1 &
        sleep 2
        log "${EDITOR_NAME} launched"
    else
        info "Open your editor manually and open the Continue panel."
    fi
}

print_summary() {
    section "Setup Complete"

    echo -e "  ${BOLD}${WHITE}Configured Models:${RESET}"
    local fallback_listed=false
    for m in "${FINAL_MODELS[@]}"; do
        if [ "$m" = "$FALLBACK_MODEL" ]; then
            fallback_listed=true
            echo -e "    ${BOLD}${CYAN}•${RESET} ${BOLD}${GREEN}${m}${RESET}  ${DIM}[chat, edit, tab-autocomplete]${RESET}"
        else
            echo -e "    ${BOLD}${CYAN}•${RESET} ${BOLD}${GREEN}${m}${RESET}  ${DIM}[chat, edit]${RESET}"
        fi
    done
    if [ "$fallback_listed" = false ]; then
        echo -e "    ${BOLD}${CYAN}•${RESET} ${BOLD}${GREEN}${FALLBACK_MODEL}${RESET}  ${DIM}[tab-autocomplete]${RESET}"
    fi
    echo -e "    ${BOLD}${CYAN}•${RESET} ${BOLD}${GREEN}${EMBEDDING_MODEL}${RESET}  ${DIM}[@codebase RAG]${RESET}"

    blank
    echo -e "  ${BOLD}${WHITE}Editor         ${RESET}${DIM}|${RESET}  ${BOLD}${CYAN}${EDITOR_NAME}${RESET}"
    echo -e "  ${BOLD}${WHITE}Config File    ${RESET}${DIM}|${RESET}  ${DIM}$HOME/.continue/config.yaml${RESET}"
    echo -e "  ${BOLD}${WHITE}Ollama Status  ${RESET}${DIM}|${RESET}  $(ollama_ready \
              && echo -e "${BOLD}${GREEN}Running${RESET}" \
              || echo -e "${BOLD}${RED}Not Running${RESET}")"
    blank
    echo -e "  ${BOLD}${YELLOW}Open your editor -> Click Continue icon on sidebar -> Start coding with AI!${RESET}"
    blank
}

open_github() {
    local url="https://github.com/moshiurrahmandeap11"

    blank
    echo -e "${BOLD}${CYAN}  ╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║                                                        ║${RESET}"
    echo -e "${BOLD}${CYAN}  ║  ${WHITE}  Thanks for using Just One Installer                ${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║  ${WHITE}  Developer  :  github.com/moshiurrahmandeap11       ${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║                                                        ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚════════════════════════════════════════════════════════╝${RESET}"
    blank

    if [ -r /dev/tty ] && command -v open &>/dev/null; then
        echo -e "  ${DIM}Star/visit the project on GitHub? [y/N]: ${RESET}\c"
        read_tty open_choice
        if [[ "$open_choice" =~ ^[yY] ]]; then
            open "$url" >/dev/null 2>&1 &
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────
#  ENTRY POINT
# ─────────────────────────────────────────────────────────────────

print_banner
ensure_homebrew
detect_system
install_ollama
start_ollama
detect_editor
install_continue
fetch_models
select_mode_and_models
install_all_models
set_continue_config
open_editor
print_summary
open_github
