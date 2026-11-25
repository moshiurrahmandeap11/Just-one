#!/bin/bash

# ------------------------------------------------------------------
#  Just One  |  Local AI Automator  |  v2.5
#  Linux Version
#  Author  : Moshiur Rahman Deap
#  Website : https://one.moshiur.pro  |  https://moshiur.pro
#  Github  : https://github.com/moshiurrahmandeap11
#  LinkedIn: https://linkedin.com/in/moshiurrahmandeap
#  License : MIT
# ------------------------------------------------------------------

if [ -t 1 ]; then
    clear || true
fi
set -e

# -- Terminal Styling ----------------------------------------------
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
DARK_CYAN='\033[0;36m'
WHITE='\033[1;37m'

TOTAL_STEPS=8
BOX_INNER=64

# -- Logger & UI Helpers (Strictly Emoji-Free) ---------------------
log()   { echo -e "  ${GREEN}[OK]${RESET} ${WHITE}$1${RESET}"; }
warn()  { echo -e "  ${YELLOW}[>>]${RESET} ${YELLOW}$1${RESET}"; }
error() { echo -e "  ${RED}[!!]${RESET} ${RED}$1${RESET}"; }
info()  { echo -e "  ${CYAN}[--]${RESET} ${DIM}$1${RESET}"; }
blank() { echo ""; }

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

print_card_line() {
    local label="$1"
    local value="$2"
    local extra="$3"
    local vcolor="${4:-$CYAN}"
    local bcolor="${5:-$DARK_CYAN}"
    local prefix="  ${label}"
    local mid=" | "
    local body="${prefix}${mid}${value}${extra}"
    local pad=$(( BOX_INNER - ${#body} ))
    [ "$pad" -lt 1 ] && pad=1
    local spaces
    spaces=$(printf '%*s' "$pad" '')
    echo -e "  ${bcolor}│${DIM}${prefix}${RESET}${DIM}${mid}${vcolor}${value}${DIM}${extra}${spaces}${bcolor}│${RESET}"
}

print_step() {
    local step="$1"
    local title="$2"
    local badge="STEP 0${step}/0${TOTAL_STEPS}"
    local header=" ${badge} :: ${title} "
    local fill_len=$(( BOX_INNER - ${#header} ))
    [ "$fill_len" -lt 4 ] && fill_len=4
    local fill
    fill=$(printf '─%.0s' $(seq 1 "$fill_len"))
    blank
    echo -e "  ${DARK_CYAN}╭─ ${CYAN}${badge}${DIM} :: ${WHITE}${title} ${DARK_CYAN}${fill}${RESET}"
    blank
}

print_banner() {
    blank
    echo -e "  ${CYAN}     ██╗ ██╗   ██╗ ███████╗ ████████╗   ██████╗  ███╗   ██╗ ███████╗${RESET}"
    echo -e "  ${CYAN}     ██║ ██║   ██║ ██╔════╝ ╚══██╔══╝  ██╔═══██╗ ████╗  ██║ ██╔════╝${RESET}"
    echo -e "  ${WHITE}     ██║ ██║   ██║ ███████╗    ██║     ██║   ██║ ██╔██╗ ██║ █████╗  ${RESET}"
    echo -e "  ${WHITE}██   ██║ ██║   ██║ ╚════██║    ██║     ██║   ██║ ██║╚██╗██║ ██╔══╝  ${RESET}"
    echo -e "  ${GREEN}╚█████╔╝ ╚██████╔╝ ███████║    ██║     ╚██████╔╝ ██║ ╚████║ ███████╗${RESET}"
    echo -e "  ${GREEN} ╚════╝   ╚═════╝  ╚══════╝    ╚═╝      ╚═════╝  ╚═╝  ╚═══╝ ╚═════╝ ${RESET}"

    local border
    border=$(printf '─%.0s' $(seq 1 $BOX_INNER))
    local l1="  LOCAL AI & CODEBASE RAG AUTOMATOR  |  VERSION 2.5"
    local l2="  Created by Moshiur Rahman Deap     |  one.moshiur.pro"
    local p1=$(( BOX_INNER - ${#l1} ))
    local p2=$(( BOX_INNER - ${#l2} ))
    [ "$p1" -lt 0 ] && p1=0
    [ "$p2" -lt 0 ] && p2=0

    blank
    echo -e "  ${DARK_CYAN}╭${border}╮${RESET}"
    echo -e "  ${DARK_CYAN}│${WHITE}${l1}$(printf '%*s' "$p1" '')${DARK_CYAN}│${RESET}"
    echo -e "  ${DARK_CYAN}│${CYAN}${l2}$(printf '%*s' "$p2" '')${DARK_CYAN}│${RESET}"
    echo -e "  ${DARK_CYAN}╰${border}╯${RESET}"
    blank
}

print_budget_bar() {
    local budget="$1"
    local total="$2"
    local source="$3"
    local bar_w=24
    local filled
    if [ "$total" -gt 0 ]; then
        filled=$(( (budget * bar_w) / total ))
    else
        filled=14
    fi
    [ "$filled" -gt "$bar_w" ] && filled=$bar_w
    [ "$filled" -lt 1 ] && filled=1
    local empty=$(( bar_w - filled ))
    local f_str="" e_str=""
    [ "$filled" -gt 0 ] && f_str=$(printf '█%.0s' $(seq 1 "$filled"))
    [ "$empty" -gt 0 ] && e_str=$(printf '░%.0s' $(seq 1 "$empty"))

    local top_title="─ MEMORY SAFETY GUARD "
    local top_fill_len=$(( BOX_INNER - ${#top_title} ))
    local top_fill
    top_fill=$(printf '─%.0s' $(seq 1 "$top_fill_len"))
    local border
    border=$(printf '─%.0s' $(seq 1 $BOX_INNER))

    echo -e "  ${DARK_CYAN}╭${top_title}${top_fill}╮${RESET}"
    print_card_line "Memory Source " "${total} GB" " (${source})" "$CYAN"
    print_card_line "Safe AI Budget" "[${f_str}${e_str}] ${budget} GB" " (65% Limit)" "$GREEN"
    echo -e "  ${DARK_CYAN}╰${border}╯${RESET}"
    blank
}

spin_wait() {
    local label="$1"
    local max_sec="$2"
    shift 2
    local frames=('[|]' '[/]' '[-]' '[\]')
    local max_ticks=$(( max_sec * 5 ))
    local tick=0

    while [ "$tick" -lt "$max_ticks" ]; do
        if "$@"; then
            [ -t 1 ] && printf "\r\033[2K"
            return 0
        fi
        if [ -t 1 ]; then
            local f="${frames[$(( tick % 4 ))]}"
            printf "\r  ${CYAN}%s${RESET} %s..." "$f" "$label"
        fi
        tick=$(( tick + 1 ))
        sleep 0.2 2>/dev/null || sleep 1
    done
    [ -t 1 ] && printf "\r\033[2K"
    return 1
}

# -- Global Defaults -----------------------------------------------
FALLBACK_MODEL="qwen2.5-coder:1.5b"
EMBEDDING_MODEL="nomic-embed-text"
SELECTED=()
SUCCESSFUL_MODELS=()
FINAL_MODELS=()
MODEL_MAP=()
DETECTED_EDITOR_NAMES=()
DETECTED_EDITOR_CMDS=()
BACKUP_PATH=""
RAG_VERIFIED=false

# -----------------------------------------------------------------
#  STEP 1  |  Prerequisites & System Hardware Profile
# -----------------------------------------------------------------

ensure_curl() {
    if command -v curl &>/dev/null; then
        return
    fi

    warn "curl not found -- detecting Linux distribution..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        DISTRO=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi

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
            sudo apk add curl ;;
        void)
            sudo xbps-install -Sy curl ;;
        *)
            error "Unsupported distribution: ${DISTRO}. Please install curl manually."
            exit 1
            ;;
    esac
    log "curl installed (${DISTRO})"
}

detect_system() {
    print_step 1 "System Hardware & Memory Profile"
    ensure_curl

    CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 2)
    CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null \
                | cut -d: -f2 \
                | sed 's/^[ \t]*//;s/[ \t]*$//' \
                || true)
    [ -z "$CPU_MODEL" ] && CPU_MODEL=$(uname -m)

    RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
    [[ "$RAM_KB" =~ ^[0-9]+$ ]] || RAM_KB=0
    RAM_MB=$(( RAM_KB / 1024 ))
    RAM_GB=$(( (RAM_MB + 512) / 1024 ))
    [ "$RAM_GB" -lt 1 ] && RAM_GB=8

    GPU_VRAM=0
    GPU_NAME="Not detected"

    if command -v nvidia-smi &>/dev/null; then
        local nv_name vram_raw
        nv_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 | sed 's/^[ \t]*//' || true)
        vram_raw=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d '[:space:]' || true)
        if [[ "$vram_raw" =~ ^[0-9]+$ ]] && [ "$vram_raw" -gt 0 ]; then
            GPU_NAME="${nv_name:-NVIDIA GPU}"
            GPU_VRAM=$(( (vram_raw + 512) / 1024 ))
        fi
    elif command -v rocm-smi &>/dev/null; then
        GPU_NAME=$(rocm-smi --showproductname 2>/dev/null | awk -F: '/Card series/{print $2}' | head -1 | sed 's/^[ \t]*//' || true)
        GPU_VRAM=8
        [ -z "$GPU_NAME" ] && GPU_NAME="AMD ROCm GPU"
    fi

    DISK_FREE=$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2 {printf "%d", $4 / 1024 / 1024}' || true)
    [[ "$DISK_FREE" =~ ^[0-9]+$ ]] || DISK_FREE=20

    local cpu_disp="$CPU_MODEL"
    [ "${#cpu_disp}" -gt 35 ] && cpu_disp="${cpu_disp:0:32}..."
    local gpu_disp="$GPU_NAME"
    [ "${#gpu_disp}" -gt 35 ] && gpu_disp="${gpu_disp:0:32}..."

    local top_title="─ HARDWARE TELEMETRY "
    local top_fill
    top_fill=$(printf '─%.0s' $(seq 1 $(( BOX_INNER - ${#top_title} ))))
    local border
    border=$(printf '─%.0s' $(seq 1 $BOX_INNER))

    echo -e "  ${DARK_CYAN}╭${top_title}${top_fill}╮${RESET}"
    print_card_line "CPU      " "$cpu_disp" " (${CPU_CORES} threads)"
    print_card_line "RAM      " "${RAM_GB} GB" " (${RAM_MB} MB)"
    print_card_line "GPU      " "$gpu_disp" " (${GPU_VRAM} GB)"
    print_card_line "Disk Free" "${DISK_FREE} GB" ""
    echo -e "  ${DARK_CYAN}╰${border}╯${RESET}"

    if [ "$DISK_FREE" -lt 8 ]; then
        blank
        warn "Low disk space (${DISK_FREE} GB). Recommend at least 8 GB free for AI models."
    fi

    if [ "$GPU_VRAM" -ge 8 ]; then
        EFFECTIVE_MEM=$GPU_VRAM
        MEM_SOURCE="Dedicated GPU VRAM"
    else
        EFFECTIVE_MEM=$RAM_GB
        MEM_SOURCE="System RAM"
    fi
}

# -----------------------------------------------------------------
#  STEP 2  |  Ollama Runtime & GPU Acceleration
# -----------------------------------------------------------------

ollama_ready() {
    curl -fsS --max-time 2 "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1
}

configure_systemd_ollama_env() {
    local override_dir="/etc/systemd/system/ollama.service.d"
    local override_file="${override_dir}/just-one.conf"
    if [ -f "$override_file" ]; then
        return 0
    fi
    if sudo -n true 2>/dev/null || [ -r /dev/tty ]; then
        sudo mkdir -p "$override_dir" 2>/dev/null || return 1
        printf '[Service]\nEnvironment="OLLAMA_FLASH_ATTENTION=1"\nEnvironment="OLLAMA_KEEP_ALIVE=24h"\n' \
            | sudo tee "$override_file" >/dev/null 2>&1 || return 1
        sudo systemctl daemon-reload 2>/dev/null || true
        return 0
    fi
    return 1
}

setup_ollama() {
    print_step 2 "Ollama Runtime & GPU Acceleration"

    export OLLAMA_FLASH_ATTENTION=1
    export OLLAMA_KEEP_ALIVE="24h"
    log "Optimizations enabled: Flash Attention + 24h Model Keep-Alive"

    if command -v ollama &>/dev/null; then
        log "Ollama binary ready ($(command -v ollama))"
    else
        info "Downloading and installing Ollama..."
        if curl -fsSL https://ollama.com/install.sh | sh; then
            log "Ollama installed successfully"
        else
            error "Ollama installation failed."
            exit 1
        fi
    fi

    if ollama_ready; then
        log "Ollama API server is online (127.0.0.1:11434)"
        return
    fi

    if command -v systemctl &>/dev/null && systemctl list-unit-files 2>/dev/null | grep -q "ollama.service"; then
        configure_systemd_ollama_env || true
        if ! systemctl is-active --quiet ollama 2>/dev/null; then
            sudo systemctl start ollama || {
                warn "systemctl start failed -- falling back to background process..."
                nohup ollama serve > /dev/null 2>&1 &
            }
        fi
    elif ! pgrep -x ollama &>/dev/null; then
        nohup ollama serve > /dev/null 2>&1 &
    fi

    if spin_wait "Waiting for Ollama API server" 20 ollama_ready; then
        log "Ollama API server is online (127.0.0.1:11434)"
    else
        warn "Ollama server started; API is still warming up."
    fi
}

# -----------------------------------------------------------------
#  STEP 3  |  Code Editors & Continue Extension
# -----------------------------------------------------------------

setup_editors() {
    print_step 3 "Code Editors & Continue Extension"

    local names=("VS Code" "Cursor" "VS Code Insiders" "VSCodium")
    local cmds=("code" "cursor" "code-insiders" "codium")
    local idx=0

    DETECTED_EDITOR_NAMES=()
    DETECTED_EDITOR_CMDS=()

    while [ "$idx" -lt "${#cmds[@]}" ]; do
        local cmd="${cmds[$idx]}"
        local name="${names[$idx]}"
        if command -v "$cmd" &>/dev/null; then
            DETECTED_EDITOR_NAMES+=("$name")
            DETECTED_EDITOR_CMDS+=("$cmd")
        fi
        idx=$(( idx + 1 ))
    done

    if [ ${#DETECTED_EDITOR_CMDS[@]} -eq 0 ]; then
        warn "No supported editor CLI found on PATH (checked code, cursor, code-insiders, codium)."
        info "Config will still be generated; install VS Code or Cursor anytime to use it."
        return
    fi

    idx=0
    while [ "$idx" -lt "${#DETECTED_EDITOR_CMDS[@]}" ]; do
        local cmd="${DETECTED_EDITOR_CMDS[$idx]}"
        local name="${DETECTED_EDITOR_NAMES[$idx]}"
        local extensions
        extensions=$("$cmd" --list-extensions 2>/dev/null || true)
        if echo "$extensions" | grep -q "Continue.continue"; then
            log "${name} detected -- Continue extension ready"
        else
            info "Installing Continue extension in ${name}..."
            if "$cmd" --install-extension Continue.continue >/dev/null 2>&1; then
                log "${name} detected -- Continue extension installed"
            else
                warn "${name} detected -- could not auto-install Continue (install manually inside editor)"
            fi
        fi
        idx=$(( idx + 1 ))
    done
}

# -----------------------------------------------------------------
#  STEP 4  |  Live Ollama Model Catalog
# -----------------------------------------------------------------

fetch_ollama_models() {
    print_step 4 "Live Ollama Model Catalog"

    local raw_html
    raw_html=$(curl -s --max-time 8 "https://ollama.com/library" 2>/dev/null || true)

    local models
    models=$(echo "$raw_html" | sed -n 's/.*href="\/library\/\([a-zA-Z0-9_.:-]*\)".*/\1/p' | sort -u)

    if [ -z "$models" ]; then
        warn "Could not reach ollama.com -- using built-in curated catalog"
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

    log "${#OLLAMA_MODELS[@]} model families ready for hardware filtering"
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

# -----------------------------------------------------------------
#  STEP 5  |  Interactive Mode Picker (Strict Fixed-Width Alignment)
# -----------------------------------------------------------------

render_mode_box() {
    local current="$1"
    local hint="$2"
    local border
    border=$(printf '─%.0s' $(seq 1 $BOX_INNER))

    local o1 o2 c1 c2
    if [ "$current" -eq 1 ]; then
        o1="  > [1] Express Auto Setup   | Recommended for your specs"
        o2="    [2] Custom Model Picker  | Pick from live Ollama catalog"
        c1="$CYAN"
        c2="$DIM"
    else
        o1="    [1] Express Auto Setup   | Recommended for your specs"
        o2="  > [2] Custom Model Picker  | Pick from live Ollama catalog"
        c1="$DIM"
        c2="$YELLOW"
    fi

    local p1=$(( BOX_INNER - ${#o1} ))
    local p2=$(( BOX_INNER - ${#o2} ))
    [ "$p1" -lt 0 ] && p1=0
    [ "$p2" -lt 0 ] && p2=0

    echo -e "\r\033[2K  ${DARK_CYAN}╭${border}╮${RESET}"
    echo -e "\r\033[2K  ${DARK_CYAN}│${c1}${o1}$(printf '%*s' "$p1" '')${DARK_CYAN}│${RESET}"
    echo -e "\r\033[2K  ${DARK_CYAN}│${c2}${o2}$(printf '%*s' "$p2" '')${DARK_CYAN}│${RESET}"
    echo -e "\r\033[2K  ${DARK_CYAN}╰${border}╯${RESET}"
    echo -e "\r\033[2K  ${WHITE}${hint}${RESET}"
}

select_mode_and_models() {
    local max_model_size=$(( (EFFECTIVE_MEM * 65) / 100 ))
    [ "$max_model_size" -lt 1 ] && max_model_size=1

    print_step 5 "Model Setup Mode"
    print_budget_bar "$max_model_size" "$EFFECTIVE_MEM" "$MEM_SOURCE"

    local choice=1

    if [ "${JUST_ONE_AUTO:-0}" != "1" ] && [ -t 1 ] && [ -r /dev/tty ]; then
        echo -e "  ${WHITE}Select installation mode:${RESET}"
        blank
        render_mode_box 1 "Use Up/Down or 1/2 to choose, then press [Enter]"

        while true; do
            local key=""
            if ! IFS= read -rsn1 key < /dev/tty; then
                break
            fi
            if [ "$key" = $'\x1b' ]; then
                local seq_rest=""
                IFS= read -rsn2 -t 1 seq_rest < /dev/tty || true
                if [ "$seq_rest" = "[A" ]; then
                    choice=1
                elif [ "$seq_rest" = "[B" ]; then
                    choice=2
                else
                    continue
                fi
            elif [ "$key" = "1" ]; then
                choice=1
            elif [ "$key" = "2" ]; then
                choice=2
            elif [ "$key" = "c" ] || [ "$key" = "C" ]; then
                choice=2
                printf "\033[5A"
                render_mode_box "$choice" "Selected [2] Custom Model Picker"
                break
            elif [ -z "$key" ]; then
                printf "\033[5A"
                render_mode_box "$choice" "Confirmed [$choice]"
                break
            else
                continue
            fi
            printf "\033[5A"
            render_mode_box "$choice" "Selected [$choice] -- press [Enter] to confirm"
        done
        blank
    fi

    if [ "$choice" -eq 1 ]; then
        if [ "$EFFECTIVE_MEM" -ge 24 ]; then
            SELECTED=("qwen2.5-coder:14b" "deepseek-r1:8b")
        elif [ "$EFFECTIVE_MEM" -ge 12 ]; then
            SELECTED=("qwen2.5-coder:7b" "deepseek-r1:7b")
        elif [ "$EFFECTIVE_MEM" -ge 8 ]; then
            SELECTED=("qwen2.5-coder:7b")
        else
            SELECTED=("qwen2.5-coder:3b")
        fi
        log "Express Preset (${EFFECTIVE_MEM} GB ${MEM_SOURCE}): ${SELECTED[*]}"
        return
    fi

    # Custom Table Selection
    printf "  ${WHITE}%-4s  %-28s  %-9s  %s${RESET}\n" "No." "Model Family" "Est.Size" "Role"
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
            printf "  ${CYAN}%2d)${RESET}  %-28s  ~%-7s  ${YELLOW}[%s]${RESET}\n" "$num" "$model" "${size} GB" "$tag"
            num=$(( num + 1 ))
        fi
    done

    blank
    info "Enter comma-separated numbers (e.g. 1,3), or press Enter for default fallback."
    echo -e "  ${CYAN}Your choice: ${RESET}\c"
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

# -----------------------------------------------------------------
#  STEP 6  |  Download AI & Embedding Models
# -----------------------------------------------------------------

is_model_installed() {
    local model="$1"
    local target="$model"
    if [[ "$model" != *:* ]]; then
        target="${model}:latest"
    fi
    ollama list 2>/dev/null | awk -v m="$model" -v t="$target" 'NR>1 && ($1 == t || $1 == m) {found=1; exit} END{exit !found}'
}

install_all_models() {
    print_step 6 "Downloading AI & Embedding Models"

    if ! command -v ollama &>/dev/null; then
        error "Ollama command not found. Please restart your terminal and run again."
        exit 1
    fi

    if [ ${#SELECTED[@]} -gt 0 ]; then
        for model in "${SELECTED[@]}"; do
            if is_model_installed "$model"; then
                log "$model -- already installed"
                SUCCESSFUL_MODELS+=("$model")
            else
                info "Pulling $model ..."
                if ollama pull "$model"; then
                    log "$model -- installed"
                    SUCCESSFUL_MODELS+=("$model")
                else
                    warn "Failed to pull $model -- skipped"
                fi
            fi
        done
    fi

    blank
    if is_model_installed "${FALLBACK_MODEL}"; then
        log "${FALLBACK_MODEL} [tab-autocomplete] -- already installed"
    else
        info "Pulling tab-autocomplete model: ${FALLBACK_MODEL} ..."
        if ollama pull "${FALLBACK_MODEL}"; then
            log "${FALLBACK_MODEL} [tab-autocomplete] -- installed"
        else
            warn "Could not pull ${FALLBACK_MODEL}"
        fi
    fi

    if is_model_installed "${EMBEDDING_MODEL}"; then
        log "${EMBEDDING_MODEL} [@codebase RAG] -- already installed"
    else
        info "Pulling embedding model: ${EMBEDDING_MODEL} (274 MB) ..."
        if ollama pull "${EMBEDDING_MODEL}"; then
            log "${EMBEDDING_MODEL} [@codebase RAG] -- installed"
        else
            warn "Could not pull ${EMBEDDING_MODEL}"
        fi
    fi

    FINAL_MODELS=()
    if [ ${#SUCCESSFUL_MODELS[@]} -gt 0 ]; then
        FINAL_MODELS=("${SUCCESSFUL_MODELS[@]}")
    else
        FINAL_MODELS=("$FALLBACK_MODEL")
    fi
}

# -----------------------------------------------------------------
#  STEP 7  |  Backup & Write Continue Config (Pure YAML v1)
# -----------------------------------------------------------------

set_continue_config() {
    print_step 7 "Writing Continue Config & Rules"

    local config_dir="$HOME/.continue"
    mkdir -p "$config_dir"
    local config_file="$config_dir/config.yaml"
    local rules_file="$config_dir/.continuerules"
    BACKUP_PATH=""

    if [ -f "$config_file" ]; then
        local stamp
        stamp=$(date +"%Y%m%d-%H%M%S")
        BACKUP_PATH="$config_dir/config.yaml.bak.$stamp"
        cp "$config_file" "$BACKUP_PATH" 2>/dev/null && info "Existing config backed up -> $BACKUP_PATH" || BACKUP_PATH=""
    fi

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

    log "Continue YAML v1 written -> $config_file"

    cat > "$rules_file" << 'EOF'
# Local AI Development Rules
- Write clean, modular, modern, and well-typed code.
- Always include error handling and handle edge cases gracefully.
- Follow idioms and conventions of the target programming language.
- Do not leave unfinished placeholder comments like '// TODO' without implementation.
EOF
    log "Developer rules written -> $rules_file"
}

# -----------------------------------------------------------------
#  STEP 8  |  Live Health Check, Editor Launch & Summary
# -----------------------------------------------------------------

health_check_and_launch() {
    print_step 8 "Health Check & Editor Launch"

    RAG_VERIFIED=false
    if ollama_ready; then
        if curl -fsS --max-time 15 -X POST "http://127.0.0.1:11434/api/embeddings" \
            -H "Content-Type: application/json" \
            -d "{\"model\":\"${EMBEDDING_MODEL}\",\"prompt\":\"just one health check\"}" >/dev/null 2>&1; then
            RAG_VERIFIED=true
            log "Verified local embeddings (@codebase RAG) with ${EMBEDDING_MODEL}"
        else
            warn "Embeddings warmup skipped (will initialize on first @codebase query)"
        fi
    fi

    if [ ${#DETECTED_EDITOR_CMDS[@]} -gt 0 ]; then
        local primary_cmd="${DETECTED_EDITOR_CMDS[0]}"
        local primary_name="${DETECTED_EDITOR_NAMES[0]}"
        "$primary_cmd" . >/dev/null 2>&1 &
        log "Launched ${primary_name} in current directory"
    fi
}

print_summary() {
    local border
    border=$(printf '─%.0s' $(seq 1 $BOX_INNER))
    local title="  [OK] JUST ONE SETUP COMPLETE"
    local pad=$(( BOX_INNER - ${#title} ))
    [ "$pad" -lt 0 ] && pad=0

    blank
    echo -e "  ${GREEN}╭${border}╮${RESET}"
    echo -e "  ${GREEN}│${WHITE}${title}$(printf '%*s' "$pad" '')${GREEN}│${RESET}"
    echo -e "  ${GREEN}╰${border}╯${RESET}"
    blank

    echo -e "  ${WHITE}Active Models:${RESET}"
    local fallback_listed=false
    for m in "${FINAL_MODELS[@]}"; do
        if [ "$m" = "$FALLBACK_MODEL" ]; then
            fallback_listed=true
            echo -e "    ${CYAN}+${RESET} ${GREEN}${m}${RESET}  ${DIM}[chat, edit, tab-autocomplete]${RESET}"
        else
            echo -e "    ${CYAN}+${RESET} ${GREEN}${m}${RESET}  ${DIM}[chat, edit]${RESET}"
        fi
    done
    if [ "$fallback_listed" = false ]; then
        echo -e "    ${CYAN}+${RESET} ${GREEN}${FALLBACK_MODEL}${RESET}  ${DIM}[tab-autocomplete]${RESET}"
    fi
    echo -e "    ${CYAN}+${RESET} ${GREEN}${EMBEDDING_MODEL}${RESET}  ${DIM}[@codebase RAG]${RESET}"

    blank
    local editor_summary="None detected"
    if [ ${#DETECTED_EDITOR_NAMES[@]} -gt 0 ]; then
        editor_summary=$(IFS=', '; echo "${DETECTED_EDITOR_NAMES[*]}")
    fi
    local api_text="Warming up"
    local api_color="$YELLOW"
    if ollama_ready; then
        api_text="Online (127.0.0.1:11434)"
        api_color="$GREEN"
    fi
    local rag_text="On-demand"
    local rag_color="$DIM"
    if [ "$RAG_VERIFIED" = true ]; then
        rag_text="Verified"
        rag_color="$GREEN"
    fi

    local top_title="─ DEPLOYMENT SUMMARY "
    local top_fill
    top_fill=$(printf '─%.0s' $(seq 1 $(( BOX_INNER - ${#top_title} ))))
    echo -e "  ${DARK_CYAN}╭${top_title}${top_fill}╮${RESET}"
    print_card_line "Editors   " "$editor_summary" "" "$CYAN"
    print_card_line "Config    " "~/.continue/config.yaml" "" "$WHITE"
    [ -n "$BACKUP_PATH" ] && print_card_line "Backup    " "$(basename "$BACKUP_PATH")" "" "$DIM"
    print_card_line "Ollama API" "$api_text" "" "$api_color"
    print_card_line "RAG Status" "$rag_text" "" "$rag_color"
    echo -e "  ${DARK_CYAN}╰${border}╯${RESET}"

    blank
    echo -e "  ${WHITE}Quick Shortcuts:${RESET}"
    echo -e "    ${DIM}Ctrl+L  Chat with AI      |  Ctrl+I     Inline Code Edit${RESET}"
    echo -e "    ${DIM}Tab     FIM Autocomplete  |  @codebase  Semantic Project Search${RESET}"
    blank

    local c1="  Engineered by Moshiur Rahman Deap"
    local c2="  Web: https://one.moshiur.pro  |  https://moshiur.pro"
    local c3="  Git: https://github.com/moshiurrahmandeap11"
    echo -e "  ${DIM}╭${border}╮${RESET}"
    echo -e "  ${DIM}│${CYAN}${c1}$(printf '%*s' $(( BOX_INNER - ${#c1} )) '')${DIM}│${RESET}"
    echo -e "  ${DIM}│${RESET}${c2}$(printf '%*s' $(( BOX_INNER - ${#c2} )) '')${DIM}│${RESET}"
    echo -e "  ${DIM}│${RESET}${c3}$(printf '%*s' $(( BOX_INNER - ${#c3} )) '')${DIM}│${RESET}"
    echo -e "  ${DIM}╰${border}╯${RESET}"
    blank
}

open_github() {
    local url="https://github.com/moshiurrahmandeap11"
    if [ "${JUST_ONE_AUTO:-0}" != "1" ] && [ -r /dev/tty ] && (command -v xdg-open &>/dev/null || command -v open &>/dev/null); then
        echo -e "  ${DIM}Star/visit github.com/moshiurrahmandeap11? [y/N]: ${RESET}\c"
        read_tty open_choice
        if [[ "$open_choice" =~ ^[yY] ]]; then
            if command -v xdg-open &>/dev/null; then
                xdg-open "$url" >/dev/null 2>&1 &
            elif command -v open &>/dev/null; then
                open "$url" >/dev/null 2>&1 &
            fi
        fi
    fi
}

# -----------------------------------------------------------------
#  ENTRY POINT
# -----------------------------------------------------------------

print_banner
detect_system
setup_ollama
setup_editors
fetch_ollama_models
select_mode_and_models
install_all_models
set_continue_config
health_check_and_launch
print_summary
open_github
