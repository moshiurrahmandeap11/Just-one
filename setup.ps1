# ──────────────────────────────────────────────────────────────────
#  Just One  |  Local AI Automator  |  v2.5
#  Windows PowerShell Version
#  Author : Moshiur Rahman Deap
#  Contact: https://www.linkedin.com/in/moshiurrahmandeap
#  Github : https://github.com/moshiurrahmandeap11
#  License: MIT
# ──────────────────────────────────────────────────────────────────

Clear-Host
$ErrorActionPreference = "Stop"

# Ensure execution policy allows script execution for CurrentUser
try {
    $currentUserPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
    if ($currentUserPolicy -ne 'RemoteSigned' -and $currentUserPolicy -ne 'Unrestricted' -and $currentUserPolicy -ne 'Bypass') {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        Write-Host "  OK   " -NoNewline -ForegroundColor Green; Write-Host "  ExecutionPolicy set to RemoteSigned for CurrentUser" -ForegroundColor White
    }
} catch {
    # Proceed even if policy setting fails
}

# ── PowerShell Host Configuration ────────────────────────────────
$Host.UI.RawUI.WindowTitle = "Just One Installer v2.5"

# ── Color Functions ──────────────────────────────────────────────
function Write-Log { Write-Host "  OK  " -NoNewline -ForegroundColor Green; Write-Host "  $args" -ForegroundColor White }
function Write-Warn { Write-Host "  >>  " -NoNewline -ForegroundColor Yellow; Write-Host "  $args" -ForegroundColor White }
function Write-Error { Write-Host "  !!  " -NoNewline -ForegroundColor Red; Write-Host "  $args" -ForegroundColor White }
function Write-Info { Write-Host "  --  " -NoNewline -ForegroundColor Cyan; Write-Host "  $args" }
function Write-Blank { Write-Host "" }

# ── Section Header ────────────────────────────────────────────────
function Write-Section {
    param([string]$Title)
    $width = 56
    $line = "═" * $width
    $inner = $width - 2
    $pad = [math]::Floor(($inner - $Title.Length) / 2)
    $rpad = $inner - $Title.Length - $pad
    $spacesL = " " * $pad
    $spacesR = " " * $rpad

    Write-Blank
    Write-Host "  ╔$line╗" -ForegroundColor Cyan
    Write-Host "  ║$spacesL" -NoNewline -ForegroundColor Cyan
    Write-Host "$Title" -NoNewline -ForegroundColor White
    Write-Host "$spacesR║" -ForegroundColor Cyan
    Write-Host "  ╚$line╝" -ForegroundColor Cyan
    Write-Blank
}

# ── Banner ────────────────────────────────────────────────────────
function Show-Banner {
    Write-Host ""
    Write-Host "  ╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                        ║" -ForegroundColor Cyan
    Write-Host "  ║           Just One Installer  v2.5                     ║" -ForegroundColor Cyan
    Write-Host "  ║       Zero-Config Local AI & Codebase RAG              ║" -ForegroundColor Cyan
    Write-Host "  ║       Developed By Moshiur Rahman Deap                 ║" -ForegroundColor Cyan
    Write-Host "  ║                                                        ║" -ForegroundColor Cyan
    Write-Host "  ╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ─────────────────────────────────────────────────────────────────
#  STEP 1  |  Collect system hardware information
# ─────────────────────────────────────────────────────────────────

function Get-SystemInfo {
    Write-Section "System Information"

    # CPU Info
    $cpuInfo = Get-CimInstance Win32_Processor | Select-Object -First 1
    $CPU_MODEL = $cpuInfo.Name.Trim()
    $CPU_CORES = $cpuInfo.NumberOfLogicalProcessors

    # RAM Info
    $os = Get-CimInstance Win32_OperatingSystem
    $RAM_GB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $RAM_MB = [math]::Round($os.TotalVisibleMemorySize / 1KB, 0)

    # GPU Info
    $GPU_VRAM = 0
    $GPU_NAME = "Not detected"

    try {
        $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.AdapterRAM -gt 0 } | Select-Object -First 1
        if ($gpu) {
            $GPU_NAME = $gpu.Name
            $GPU_VRAM = [math]::Round($gpu.AdapterRAM / 1GB, 1)
        }
    }
    catch {}

    # Check for NVIDIA specifically via nvidia-smi
    if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
        $nvidiaInfo = nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>$null
        if ($nvidiaInfo) {
            $nvidiaData = $nvidiaInfo -split ','
            $GPU_NAME = $nvidiaData[0].Trim()
            $GPU_VRAM = [math]::Round([int]($nvidiaData[1].Trim() -replace ' MiB', '') / 1024, 1)
        }
    }

    # Disk Info
    $disk = Get-PSDrive -Name (Get-Location).Drive.Name
    $DISK_FREE = [math]::Round($disk.Free / 1GB, 1)

    Write-Host "  CPU        " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$CPU_MODEL" -NoNewline -ForegroundColor Cyan
    Write-Host "  ($CPU_CORES cores)" -ForegroundColor DarkGray

    Write-Host "  RAM        " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$RAM_GB GB" -NoNewline -ForegroundColor Cyan
    Write-Host "  ($RAM_MB MB)" -ForegroundColor DarkGray

    Write-Host "  GPU        " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$GPU_NAME" -ForegroundColor Cyan

    Write-Host "  VRAM       " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$GPU_VRAM GB" -ForegroundColor Cyan

    Write-Host "  Disk Free  " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$DISK_FREE GB" -ForegroundColor Cyan

    Write-Blank

    # Save to script scope
    $script:RAM_GB = $RAM_GB
    $script:RAM_MB = $RAM_MB
    $script:CPU_CORES = $CPU_CORES
    $script:CPU_MODEL = $CPU_MODEL
    $script:GPU_VRAM = $GPU_VRAM
    $script:GPU_NAME = $GPU_NAME
    $script:DISK_FREE = $DISK_FREE

    if ($GPU_VRAM -ge 8) {
        $script:EFFECTIVE_MEM = $GPU_VRAM
        $script:MEM_SOURCE = "GPU VRAM"
    } else {
        $script:EFFECTIVE_MEM = $RAM_GB
        $script:MEM_SOURCE = "System RAM"
    }
}

# ─────────────────────────────────────────────────────────────────
#  STEP 2  |  Configure Ollama High-Performance Environment
# ─────────────────────────────────────────────────────────────────

function Configure-OllamaOptimization {
    try {
        [System.Environment]::SetEnvironmentVariable("OLLAMA_FLASH_ATTENTION", "1", "User")
        [System.Environment]::SetEnvironmentVariable("OLLAMA_KEEP_ALIVE", "24h", "User")
        $env:OLLAMA_FLASH_ATTENTION = "1"
        $env:OLLAMA_KEEP_ALIVE = "24h"
        Write-Log "Optimizations enabled: Flash Attention + 24h Model Keep-Alive"
    } catch {}
}

# ─────────────────────────────────────────────────────────────────
#  STEP 3  |  Install and Start Ollama
# ─────────────────────────────────────────────────────────────────

function Get-OllamaPath {
    $ollamaExe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
    if (Test-Path $ollamaExe) {
        return $ollamaExe
    }

    $command = Get-Command ollama -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Path
    }

    return $null
}

function Install-Ollama {
    Write-Section "Ollama Installation"

    $ollamaPath = Get-OllamaPath
    if ($ollamaPath) {
        Write-Log "Ollama is already installed"
        return
    }

    Write-Warn "Downloading Ollama installer..."
    $ollamaUrl = "https://ollama.com/download/OllamaSetup.exe"
    $installerPath = "$env:TEMP\OllamaSetup.exe"

    Invoke-WebRequest -Uri $ollamaUrl -OutFile $installerPath
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue

    Write-Log "Ollama installed successfully"
}

function Start-Ollama {
    $ollamaProcess = Get-Process ollama -ErrorAction SilentlyContinue
    if ($ollamaProcess) {
        Write-Log "Ollama server is already running"
        return
    }

    Write-Warn "Starting Ollama background server..."
    $ollamaPath = Get-OllamaPath
    if (-not $ollamaPath) {
        $ollamaPath = "ollama"
    }

    Start-Process -FilePath $ollamaPath -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 4
    Write-Log "Ollama server started"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 4  |  Multi-Editor Detection & Continue Extension
# ─────────────────────────────────────────────────────────────────

function Detect-Editor {
    Write-Section "Checking AI Code Editor"

    $editors = @(
        @{ Name = "VS Code"; Cmd = "code" },
        @{ Name = "Cursor"; Cmd = "cursor" },
        @{ Name = "VS Code Insiders"; Cmd = "code-insiders" },
        @{ Name = "VSCodium"; Cmd = "codium" }
    )

    $script:SELECTED_EDITOR = $null
    foreach ($ed in $editors) {
        if (Get-Command $ed.Cmd -ErrorAction SilentlyContinue) {
            $script:SELECTED_EDITOR = $ed
            Write-Log "$($ed.Name) CLI found ($($ed.Cmd))"
            break
        }
    }

    if (-not $script:SELECTED_EDITOR) {
        Write-Warn "No supported editor CLI found on PATH (checked code, cursor, code-insiders, codium)."
        Write-Host "  Please install VS Code (https://code.visualstudio.com) and ensure 'code' command is in PATH." -ForegroundColor DarkGray
        Write-Info "Configuration will still be generated for when you open your editor."
        $script:SELECTED_EDITOR = @{ Name = "VS Code"; Cmd = "code" }
    }
}

function Install-Continue {
    $cmd = $script:SELECTED_EDITOR.Cmd
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Warn "Could not run '$cmd --install-extension'. Install Continue manually from the extension marketplace."
        return
    }

    $extensions = & $cmd --list-extensions 2>$null
    if ($extensions -match "Continue.continue") {
        Write-Log "Continue extension is already installed in $($script:SELECTED_EDITOR.Name)"
        return
    }

    Write-Warn "Installing Continue extension in $($script:SELECTED_EDITOR.Name)..."
    & $cmd --install-extension Continue.continue
    Write-Log "Continue extension installed"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 5  |  Model Catalog & Size Estimation
# ─────────────────────────────────────────────────────────────────

function Get-OllamaModels {
    Write-Section "Fetching Ollama Model Library"
    Write-Info "Connecting to ollama.com/library..."

    try {
        $response = Invoke-WebRequest -Uri "https://ollama.com/library" -UseBasicParsing -TimeoutSec 8
        $content = $response.Content
        $pattern = 'href="/library/([^"]+)"'
        $matches = [regex]::Matches($content, $pattern)
        $OLLAMA_MODELS = ($matches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique) -join "`n"
    }
    catch {
        Write-Warn "Could not reach ollama.com -- using built-in model list"
        $OLLAMA_MODELS = "deepseek-r1`nqwen2.5-coder`nllama3.2`nllama3.1`nmistral`ncodellama`nphi4`ngemma2`nllava"
    }

    $script:OLLAMA_MODELS = $OLLAMA_MODELS
    $count = ($OLLAMA_MODELS -split "`n").Count
    Write-Log "$count model families loaded"
}

function Get-ModelSizeGB {
    param([string]$Model)

    $pattern = '[\d]+\.?[\d]*(?=b)'
    $matches = [regex]::Matches($Model, $pattern, 'IgnoreCase')

    if ($matches.Count -eq 0) {
        if ($Model -match "llama3.2") { return 2 }
        if ($Model -match "qwen2.5-coder") { return 4 }
        if ($Model -match "deepseek-r1") { return 4 }
        return 4
    }

    $raw = $matches[$matches.Count - 1].Value
    $intPart = ($raw -split '\.')[0]
    if (-not $intPart -or [int]$intPart -eq 0) { $intPart = 1 }

    $params = [int]$intPart
    $size = [math]::Ceiling($params * 0.55)
    if ($size -lt 1) { $size = 1 }
    return $size
}

function Get-ModelTag {
    param([string]$Model)

    if ($Model -match "coder|code|starcoder") { return "Coder" }
    if ($Model -match "deepseek-r1|qwq") { return "Reasoning" }
    if ($Model -match "llava|vision|minicpm-v") { return "Vision" }
    return "General"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 6  |  Selection Presets vs Custom
# ─────────────────────────────────────────────────────────────────

function Select-ModeAndModels {
    Write-Section "Model Setup Mode"

    $MAX_MODEL_SIZE = [math]::Floor($EFFECTIVE_MEM * 0.65)
    if ($MAX_MODEL_SIZE -lt 1) { $MAX_MODEL_SIZE = 1 }

    Write-Host "  Memory Source    " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$EFFECTIVE_MEM GB  ($MEM_SOURCE)" -ForegroundColor Cyan

    Write-Host "  Max Model Budget " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$MAX_MODEL_SIZE GB (Safe 65% limit)" -ForegroundColor Yellow
    Write-Blank

    Write-Host "  Choose your setup preference:" -ForegroundColor White
    Write-Blank
    Write-Host "  [1] ⚡ Quick Recommended Setup (1-Click)" -ForegroundColor Cyan
    Write-Host "      Auto-installs best Chat/Coding model + Fast Autocomplete + Codebase RAG" -ForegroundColor DarkGray
    Write-Blank
    Write-Host "  [2] 🛠️  Custom Model Selection" -ForegroundColor Yellow
    Write-Host "      Browse dynamic table and pick individual models by number" -ForegroundColor DarkGray
    Write-Blank

    Write-Host "  Your choice [1/2, default: 1]: " -NoNewline -ForegroundColor White
    $modeChoice = Read-Host

    $script:SELECTED = @()
    $script:FALLBACK_MODEL = "qwen2.5-coder:1.5b"
    $script:EMBEDDING_MODEL = "nomic-embed-text"

    if ([string]::IsNullOrWhiteSpace($modeChoice) -or $modeChoice.Trim() -eq "1") {
        # Quick Preset
        Write-Blank
        Write-Log "Applying Quick Recommended Preset for $EFFECTIVE_MEM GB $MEM_SOURCE..."

        if ($EFFECTIVE_MEM -ge 24) {
            $script:SELECTED = @("qwen2.5-coder:14b", "deepseek-r1:8b")
        } elseif ($EFFECTIVE_MEM -ge 12) {
            $script:SELECTED = @("qwen2.5-coder:7b", "deepseek-r1:7b")
        } elseif ($EFFECTIVE_MEM -ge 8) {
            $script:SELECTED = @("qwen2.5-coder:7b")
        } else {
            $script:SELECTED = @("qwen2.5-coder:3b")
        }

        Write-Info "Auto-selected models: $($script:SELECTED -join ', ')"
        return
    }

    # Custom Selection Mode
    Write-Section "Available Models"
    $displayNames = @()
    $displaySizes = @()
    $displayTags = @()
    $modelMap = @{}
    $i = 1

    foreach ($model in ($OLLAMA_MODELS -split "`n")) {
        if ([string]::IsNullOrWhiteSpace($model)) { continue }

        $SIZE = Get-ModelSizeGB -Model $model
        if ($SIZE -le $MAX_MODEL_SIZE) {
            $roleTag = Get-ModelTag -Model $model
            $displayNames += $model
            $displaySizes += $SIZE
            $displayTags += $roleTag
            $modelMap[$i] = $model
            $i++
        }
    }

    $script:MODEL_MAP = $modelMap

    Write-Host ("  {0,-4}  {1,-28}  {2,-9}  {3}" -f 'No.', 'Model', 'Size', 'Category') -ForegroundColor White
    Write-Host ("  {0,-4}  {1,-28}  {2,-9}  {3}" -f '----', '----------------------------', '---------', '--------') -ForegroundColor DarkGray

    for ($j = 0; $j -lt $displayNames.Count; $j++) {
        $num = $j + 1
        Write-Host "  " -NoNewline
        Write-Host ("{0,2})" -f $num) -NoNewline -ForegroundColor Cyan
        Write-Host "  {0,-26}" -f $displayNames[$j] -NoNewline -ForegroundColor White
        Write-Host "~$($displaySizes[$j]) GB    " -NoNewline -ForegroundColor DarkGray
        Write-Host "[$($displayTags[$j])]" -ForegroundColor Yellow
    }

    Write-Blank
    Write-Host "  Select models by entering row numbers separated by commas (e.g. 1,3)" -ForegroundColor DarkGray
    Write-Host "  Press Enter to skip manual models and use the default coder fallback." -ForegroundColor DarkGray
    Write-Blank
    Write-Host "  Your choice: " -NoNewline -ForegroundColor Cyan
    $input = Read-Host

    if (-not [string]::IsNullOrWhiteSpace($input) -and $input -ne "0") {
        $numbers = $input -split ',' | ForEach-Object { $_.Trim() }
        foreach ($num in $numbers) {
            if ($modelMap.ContainsKey([int]$num)) {
                $script:SELECTED += $modelMap[[int]$num]
            } else {
                Write-Warn "Invalid entry: $num -- skipped"
            }
        }
    }
}

# ─────────────────────────────────────────────────────────────────
#  STEP 7  |  Download Models (Selected + Fallback + Embedding)
# ─────────────────────────────────────────────────────────────────

function Install-AllModels {
    Write-Section "Downloading AI Models"

    $ollamaPath = Get-OllamaPath
    if (-not $ollamaPath) {
        Write-Error "Ollama executable not found. Please restart your terminal and run again."
        exit 1
    }

    $script:SUCCESSFUL_MODELS = @()

    # 1. Pull Selected Models
    if ($SELECTED.Count -gt 0) {
        foreach ($m in $SELECTED) {
            try {
                $installed = & $ollamaPath list 2>$null | Select-String "^$m(\s|:)"
                if ($installed) {
                    Write-Log "$m -- already installed"
                    $script:SUCCESSFUL_MODELS += $m
                } else {
                    Write-Warn "Pulling $m ..."
                    & $ollamaPath pull $m
                    Write-Log "$m -- installed"
                    $script:SUCCESSFUL_MODELS += $m
                }
            } catch {
                Write-Warn "Failed to pull $m -- skipped"
            }
        }
    }

    # 2. Guarantee Fallback Autocomplete Model
    Write-Blank
    Write-Info "Checking Tab-Autocomplete model ($FALLBACK_MODEL)..."
    try {
        $installed = & $ollamaPath list 2>$null | Select-String "^$FALLBACK_MODEL(\s|:)"
        if ($installed) {
            Write-Log "$FALLBACK_MODEL -- already installed"
        } else {
            Write-Warn "Pulling tab-autocomplete model: $FALLBACK_MODEL ..."
            & $ollamaPath pull $FALLBACK_MODEL
            Write-Log "$FALLBACK_MODEL -- installed"
        }
    } catch {
        Write-Warn "Could not pull $FALLBACK_MODEL"
    }

    # 3. Pull Codebase Embedding Model
    Write-Blank
    Write-Info "Checking Codebase RAG Embedding model ($EMBEDDING_MODEL)..."
    try {
        $installed = & $ollamaPath list 2>$null | Select-String "^$EMBEDDING_MODEL(\s|:)"
        if ($installed) {
            Write-Log "$EMBEDDING_MODEL -- already installed"
        } else {
            Write-Warn "Pulling embedding model: $EMBEDDING_MODEL (274 MB) for @codebase RAG..."
            & $ollamaPath pull $EMBEDDING_MODEL
            Write-Log "$EMBEDDING_MODEL -- installed"
        }
    } catch {
        Write-Warn "Could not pull $EMBEDDING_MODEL. Codebase indexing may use remote provider."
    }

    # Build final model list
    $script:FINAL_MODELS = @()
    if ($script:SUCCESSFUL_MODELS.Count -gt 0) {
        $script:FINAL_MODELS = $script:SUCCESSFUL_MODELS
    } else {
        $script:FINAL_MODELS += $FALLBACK_MODEL
    }
}

# ─────────────────────────────────────────────────────────────────
#  STEP 8  |  Write Continue Configuration & Rules (Pure YAML)
# ─────────────────────────────────────────────────────────────────

function Set-ContinueConfig {
    Write-Section "Writing Continue Configuration"

    $configDir = "$env:USERPROFILE\.continue"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    $configPath = "$configDir\config.yaml"
    $rulesPath = "$configDir\.continuerules"

    # Build YAML models block
    $modelsYamlLines = @()
    foreach ($m in $FINAL_MODELS) {
        if ($m -eq $FALLBACK_MODEL) {
            $modelsYamlLines += "  - name: $m`n    provider: ollama`n    model: $m`n    roles: [autocomplete]"
        } else {
            $modelsYamlLines += "  - name: $m`n    provider: ollama`n    model: $m`n    roles: [chat, edit]"
        }
    }

    # Always ensure autocomplete has the fallback model
    if (-not ($FINAL_MODELS -contains $FALLBACK_MODEL)) {
        $modelsYamlLines += "  - name: $FALLBACK_MODEL`n    provider: ollama`n    model: $FALLBACK_MODEL`n    roles: [autocomplete]"
    }

    $modelsBlock = $modelsYamlLines -join "`n`n"

    # Clean Pure YAML Configuration
    $configYaml = @"
name: Local AI Config
version: 1.0.0
schema: v1

models:
$modelsBlock

embeddingsProvider:
  provider: ollama
  model: $EMBEDDING_MODEL

tabAutocompleteModel:
  title: Tab Autocomplete
  provider: ollama
  model: $FALLBACK_MODEL

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
"@

    Set-Content -Path $configPath -Value $configYaml -Encoding UTF8
    Write-Log "Config written -- $configPath"

    # Generate Developer Rules
    $rulesContent = @"
# Local AI Development Rules
- Write clean, modular, modern, and well-typed code.
- Always include error handling and handle edge cases gracefully.
- Follow idioms and conventions of the target programming language.
- Do not leave unfinished placeholder comments like '// TODO' without implementation.
"@
    Set-Content -Path $rulesPath -Value $rulesContent -Encoding UTF8
    Write-Log "Developer rules written -- $rulesPath"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 9  |  Launch Editor & Summary
# ─────────────────────────────────────────────────────────────────

function Open-Editor {
    Write-Section "Launching Editor"
    $cmd = $script:SELECTED_EDITOR.Cmd

    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Warn "Launching $($script:SELECTED_EDITOR.Name)..."
        Start-Process $cmd -ArgumentList "." -WindowStyle Normal
        Start-Sleep -Seconds 2
        Write-Log "$($script:SELECTED_EDITOR.Name) launched in current directory"
    } else {
        Write-Info "Open your editor manually and open the Continue panel."
    }
}

function Show-Summary {
    Write-Section "Setup Complete"

    Write-Host "  Configured Models:" -ForegroundColor White
    foreach ($m in $FINAL_MODELS) {
        Write-Host "    • " -NoNewline -ForegroundColor Cyan
        Write-Host "$m" -NoNewline -ForegroundColor Green
        Write-Host " [chat, edit]" -ForegroundColor DarkGray
    }
    Write-Host "    • " -NoNewline -ForegroundColor Cyan
    Write-Host "$FALLBACK_MODEL" -NoNewline -ForegroundColor Green
    Write-Host " [tab-autocomplete]" -ForegroundColor DarkGray

    Write-Host "    • " -NoNewline -ForegroundColor Cyan
    Write-Host "$EMBEDDING_MODEL" -NoNewline -ForegroundColor Green
    Write-Host " [@codebase RAG]" -ForegroundColor DarkGray

    Write-Blank
    Write-Host "  Editor         " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($script:SELECTED_EDITOR.Name)" -ForegroundColor Cyan

    Write-Host "  Config File    " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$env:USERPROFILE\.continue\config.yaml" -ForegroundColor DarkGray

    Write-Host "  Ollama Status  " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    $ollamaRunning = Get-Process ollama -ErrorAction SilentlyContinue
    if ($ollamaRunning) {
        Write-Host "Running" -ForegroundColor Green
    } else {
        Write-Host "Not Running" -ForegroundColor Red
    }

    Write-Blank
    Write-Host "  Open your editor -> Click Continue icon on sidebar -> Start coding with AI!" -ForegroundColor Yellow
    Write-Blank
}

function Open-GitHub {
    $url = "https://github.com/moshiurrahmandeap11"

    Write-Blank
    Write-Host "  ╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                        ║" -ForegroundColor Cyan
    Write-Host "  ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "  Thanks for using Just One Installer                " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "  ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "  Developer  :  github.com/moshiurrahmandeap11       " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "  ║                                                        ║" -ForegroundColor Cyan
    Write-Host "  ╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Blank

    try {
        Start-Process $url
    } catch {}
}

# ─────────────────────────────────────────────────────────────────
#  ENTRY POINT
# ─────────────────────────────────────────────────────────────────

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Warn "Running in standard User mode (Administrator mode recommended if installing Ollama for first time)."
}

Show-Banner
Get-SystemInfo
Configure-OllamaOptimization
Install-Ollama
Start-Ollama
Detect-Editor
Install-Continue
Get-OllamaModels
Select-ModeAndModels
Install-AllModels
Set-ContinueConfig
Open-Editor
Show-Summary
Open-GitHub

Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey([System.Management.Automation.Host.ReadKeyOptions]::NoEcho -bor [System.Management.Automation.Host.ReadKeyOptions]::IncludeKeyDown)