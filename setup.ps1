# ──────────────────────────────────────────────────────────────────
#  Just One  |  Local AI Automator  |  v2.5
#  Windows PowerShell Version
#  Author : Moshiur Rahman Deap
#  Contact: https://www.linkedin.com/in/moshiurrahmandeap
#  Github : https://github.com/moshiurrahmandeap11
#  License: MIT
# ──────────────────────────────────────────────────────────────────

if ($Host.Name -eq 'ConsoleHost') {
    try { Clear-Host } catch {}
}
$ErrorActionPreference = "Stop"

# Ensure execution policy allows script execution for CurrentUser
try {
    $currentUserPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
    if ($currentUserPolicy -notin @('RemoteSigned', 'Unrestricted', 'Bypass')) {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        Write-Host "  OK   " -NoNewline -ForegroundColor Green; Write-Host "  ExecutionPolicy set to RemoteSigned for CurrentUser" -ForegroundColor White
    }
} catch {
    # Proceed even if policy setting fails
}

# ── PowerShell Host Configuration ────────────────────────────────
try { $Host.UI.RawUI.WindowTitle = "Just One Installer v2.5" } catch {}

# ── Color Functions ──────────────────────────────────────────────
function Write-Log   { Write-Host "  OK  " -NoNewline -ForegroundColor Green;  Write-Host "  $args" -ForegroundColor White }
function Write-Warn  { Write-Host "  >>  " -NoNewline -ForegroundColor Yellow; Write-Host "  $args" -ForegroundColor White }
function Write-Err   { Write-Host "  !!  " -NoNewline -ForegroundColor Red;    Write-Host "  $args" -ForegroundColor White }
function Write-Info  { Write-Host "  --  " -NoNewline -ForegroundColor Cyan;   Write-Host "  $args" }
function Write-Blank { Write-Host "" }

# ── Section Header ────────────────────────────────────────────────
function Write-Section {
    param([string]$Title)
    $width = 56
    $line = "═" * $width
    $inner = $width - 2
    $pad = [math]::Max(0, [math]::Floor(($inner - $Title.Length) / 2))
    $rpad = [math]::Max(0, $inner - $Title.Length - $pad)
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
    $CPU_MODEL = "Unknown CPU"
    $CPU_CORES = [Environment]::ProcessorCount
    try {
        $cpuInfo = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
        if ($cpuInfo -and $cpuInfo.Name) { $CPU_MODEL = $cpuInfo.Name.Trim() }
        if ($cpuInfo -and $cpuInfo.NumberOfLogicalProcessors) { $CPU_CORES = [int]$cpuInfo.NumberOfLogicalProcessors }
    } catch {}

    # RAM Info
    $RAM_GB = 8.0
    $RAM_MB = 8192
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        if ($os -and $os.TotalVisibleMemorySize) {
            $RAM_GB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            $RAM_MB = [math]::Round($os.TotalVisibleMemorySize / 1KB, 0)
        }
    } catch {}

    # GPU Info (prefer nvidia-smi, then 64-bit registry qwMemorySize, then WMI AdapterRAM)
    $GPU_VRAM = 0.0
    $GPU_NAME = "Not detected"

    if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
        try {
            $nvidiaLines = @(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>$null)
            foreach ($line in $nvidiaLines) {
                $parts = $line -split ','
                if ($parts.Count -ge 2) {
                    $vramMiB = 0
                    if ([int]::TryParse($parts[1].Trim(), [ref]$vramMiB)) {
                        $vramGB = [math]::Round($vramMiB / 1024, 1)
                        if ($vramGB -gt $GPU_VRAM) {
                            $GPU_VRAM = $vramGB
                            $GPU_NAME = $parts[0].Trim()
                        }
                    }
                }
            }
        } catch {}
    }

    if ($GPU_VRAM -eq 0) {
        try {
            $regPath = "HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0*"
            $adapters = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            foreach ($adapter in $adapters) {
                $memBytes = $adapter.'HardwareInformation.qwMemorySize'
                if ($memBytes -is [byte[]]) {
                    $memBytes = [BitConverter]::ToUInt64($memBytes, 0)
                }
                if ($memBytes -and [double]$memBytes -gt 0) {
                    $vramGB = [math]::Round([double]$memBytes / 1GB, 1)
                    if ($vramGB -gt $GPU_VRAM) {
                        $GPU_VRAM = $vramGB
                        if ($adapter.'HardwareInformation.AdapterString') {
                            $GPU_NAME = [string]$adapter.'HardwareInformation.AdapterString'
                        } elseif ($adapter.DriverDesc) {
                            $GPU_NAME = [string]$adapter.DriverDesc
                        }
                    }
                }
            }
        } catch {}
    }

    if ($GPU_VRAM -eq 0) {
        try {
            $gpus = Get-CimInstance Win32_VideoController -ErrorAction Stop | Where-Object { $_.AdapterRAM -gt 0 }
            foreach ($gpu in $gpus) {
                $vramGB = [math]::Round($gpu.AdapterRAM / 1GB, 1)
                if ($vramGB -gt $GPU_VRAM) {
                    $GPU_VRAM = $vramGB
                    $GPU_NAME = $gpu.Name
                }
            }
        } catch {}
    }

    # Disk Info (safe fallback for UNC or non-filesystem drives)
    $DISK_FREE = 0.0
    try {
        $driveName = (Get-Location).Drive.Name
        if (-not $driveName -or -not (Get-PSDrive -Name $driveName -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
            $driveName = $env:SystemDrive.TrimEnd(':')
        }
        $disk = Get-PSDrive -Name $driveName -PSProvider FileSystem -ErrorAction Stop
        $DISK_FREE = [math]::Round($disk.Free / 1GB, 1)
    } catch {}

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
    } catch {
        Write-Warn "Could not persist user environment variables; applied for current session."
        $env:OLLAMA_FLASH_ATTENTION = "1"
        $env:OLLAMA_KEEP_ALIVE = "24h"
    }
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

function Test-OllamaReady {
    try {
        $resp = Invoke-WebRequest -Uri "http://127.0.0.1:11434/api/tags" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        return ($resp.StatusCode -eq 200)
    } catch {
        return $false
    }
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

    try {
        Invoke-WebRequest -Uri $ollamaUrl -OutFile $installerPath -UseBasicParsing
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        Write-Log "Ollama installed successfully"
    } catch {
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        Write-Err "Failed to download or install Ollama: $($_.Exception.Message)"
        exit 1
    }
}

function Start-Ollama {
    if (Test-OllamaReady) {
        Write-Log "Ollama server is already running"
        return
    }

    $ollamaProcess = Get-Process ollama -ErrorAction SilentlyContinue
    if ($ollamaProcess) {
        Write-Log "Ollama process detected; waiting for API..."
    } else {
        Write-Warn "Starting Ollama background server..."
        $ollamaPath = Get-OllamaPath
        if (-not $ollamaPath) {
            Write-Err "Ollama executable not found. Please restart your terminal and run again."
            exit 1
        }
        Start-Process -FilePath $ollamaPath -ArgumentList "serve" -WindowStyle Hidden
    }

    for ($attempt = 0; $attempt -lt 15; $attempt++) {
        if (Test-OllamaReady) {
            Write-Log "Ollama server is ready"
            return
        }
        Start-Sleep -Seconds 1
    }

    Write-Warn "Ollama server started, API may still be warming up."
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
    $script:EDITOR_FOUND = $false
    foreach ($ed in $editors) {
        if (Get-Command $ed.Cmd -ErrorAction SilentlyContinue) {
            $script:SELECTED_EDITOR = $ed
            $script:EDITOR_FOUND = $true
            Write-Log "$($ed.Name) CLI found ($($ed.Cmd))"
            break
        }
    }

    if (-not $script:EDITOR_FOUND) {
        Write-Warn "No supported editor CLI found on PATH (checked code, cursor, code-insiders, codium)."
        Write-Host "  Please install VS Code (https://code.visualstudio.com) and ensure 'code' command is in PATH." -ForegroundColor DarkGray
        Write-Info "Configuration will still be generated for when you open your editor."
        $script:SELECTED_EDITOR = @{ Name = "Not detected (VS Code/Cursor)"; Cmd = "code" }
    }
}

function Install-Continue {
    if (-not $script:EDITOR_FOUND) {
        Write-Warn "Skipping auto-extension install. Install Continue manually from the extension marketplace."
        return
    }

    $cmd = $script:SELECTED_EDITOR.Cmd
    try {
        $extensions = & $cmd --list-extensions 2>$null
        if ($extensions -match "Continue\.continue") {
            Write-Log "Continue extension is already installed in $($script:SELECTED_EDITOR.Name)"
            return
        }

        Write-Warn "Installing Continue extension in $($script:SELECTED_EDITOR.Name)..."
        & $cmd --install-extension Continue.continue
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Continue extension installed"
        } else {
            Write-Warn "Could not auto-install Continue extension (exit code $LASTEXITCODE). You can install it manually inside your editor."
        }
    } catch {
        Write-Warn "Could not auto-install Continue extension: $($_.Exception.Message)"
    }
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
        $pattern = 'href="/library/([a-zA-Z0-9_.:-]+)"'
        $rxMatches = [regex]::Matches($content, $pattern)
        $familyList = $rxMatches | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ } | Sort-Object -Unique
        if ($familyList -and $familyList.Count -gt 0) {
            $OLLAMA_MODELS = $familyList -join "`n"
        } else {
            throw "Empty catalog"
        }
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

    $pattern = '(\d+(?:\.\d+)?)(?=b(?:\b|$|[-_]))'
    $rxMatches = [regex]::Matches($Model, $pattern, 'IgnoreCase')

    if ($rxMatches.Count -gt 0) {
        $raw = $rxMatches[$rxMatches.Count - 1].Groups[1].Value
        $params = 0.0
        if ([double]::TryParse($raw, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$params) -and $params -gt 0) {
            $size = [math]::Ceiling($params * 0.55)
            if ($size -lt 1) { $size = 1 }
            return [int]$size
        }
    }

    # Realistic default tag estimates for tagless library families
    if ($Model -match "qwq")          { return 18 }
    if ($Model -match "phi4")         { return 9 }
    if ($Model -match "gemma2")       { return 6 }
    if ($Model -match "llama3\.2")    { return 2 }
    if ($Model -match "llama3\.1|llama3\.3|mistral|codellama|llava|qwen2\.5-coder|deepseek-r1") { return 5 }
    return 4
}

function Get-ModelTag {
    param([string]$Model)

    if ($Model -match "coder|code|starcoder") { return "Coder" }
    if ($Model -match "deepseek-r1|qwq")      { return "Reasoning" }
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
    $userInput = Read-Host

    if (-not [string]::IsNullOrWhiteSpace($userInput) -and $userInput.Trim() -ne "0") {
        $numbers = $userInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        foreach ($num in $numbers) {
            $parsed = 0
            if ([int]::TryParse($num, [ref]$parsed) -and $modelMap.ContainsKey($parsed)) {
                $chosen = $modelMap[$parsed]
                if ($script:SELECTED -notcontains $chosen) {
                    $script:SELECTED += $chosen
                }
            } else {
                Write-Warn "Invalid entry: $num -- skipped"
            }
        }
    }
}

# ─────────────────────────────────────────────────────────────────
#  STEP 7  |  Download Models (Selected + Fallback + Embedding)
# ─────────────────────────────────────────────────────────────────

function Test-OllamaModelInstalled {
    param(
        [string]$OllamaPath,
        [string]$ModelName
    )
    $target = if ($ModelName -match ':') { $ModelName } else { "${ModelName}:latest" }
    try {
        $lines = & $OllamaPath list 2>$null
        foreach ($line in $lines) {
            $col = ($line -split '\s+')[0]
            if ($col -eq $target -or $col -eq $ModelName) {
                return $true
            }
        }
    } catch {}
    return $false
}

function Install-AllModels {
    Write-Section "Downloading AI Models"

    $ollamaPath = Get-OllamaPath
    if (-not $ollamaPath) {
        Write-Err "Ollama executable not found. Please restart your terminal and run again."
        exit 1
    }

    $script:SUCCESSFUL_MODELS = @()

    # 1. Pull Selected Models
    if ($SELECTED.Count -gt 0) {
        foreach ($m in $SELECTED) {
            try {
                if (Test-OllamaModelInstalled -OllamaPath $ollamaPath -ModelName $m) {
                    Write-Log "$m -- already installed"
                    $script:SUCCESSFUL_MODELS += $m
                } else {
                    Write-Warn "Pulling $m ..."
                    & $ollamaPath pull $m
                    if ($LASTEXITCODE -eq 0) {
                        Write-Log "$m -- installed"
                        $script:SUCCESSFUL_MODELS += $m
                    } else {
                        Write-Warn "Failed to pull $m -- skipped"
                    }
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
        if (Test-OllamaModelInstalled -OllamaPath $ollamaPath -ModelName $FALLBACK_MODEL) {
            Write-Log "$FALLBACK_MODEL -- already installed"
        } else {
            Write-Warn "Pulling tab-autocomplete model: $FALLBACK_MODEL ..."
            & $ollamaPath pull $FALLBACK_MODEL
            if ($LASTEXITCODE -eq 0) {
                Write-Log "$FALLBACK_MODEL -- installed"
            } else {
                Write-Warn "Could not pull $FALLBACK_MODEL"
            }
        }
    } catch {
        Write-Warn "Could not pull $FALLBACK_MODEL"
    }

    # 3. Pull Codebase Embedding Model
    Write-Blank
    Write-Info "Checking Codebase RAG Embedding model ($EMBEDDING_MODEL)..."
    try {
        if (Test-OllamaModelInstalled -OllamaPath $ollamaPath -ModelName $EMBEDDING_MODEL) {
            Write-Log "$EMBEDDING_MODEL -- already installed"
        } else {
            Write-Warn "Pulling embedding model: $EMBEDDING_MODEL (274 MB) for @codebase RAG..."
            & $ollamaPath pull $EMBEDDING_MODEL
            if ($LASTEXITCODE -eq 0) {
                Write-Log "$EMBEDDING_MODEL -- installed"
            } else {
                Write-Warn "Could not pull $EMBEDDING_MODEL. Codebase indexing may need manual setup."
            }
        }
    } catch {
        Write-Warn "Could not pull $EMBEDDING_MODEL. Codebase indexing may need manual setup."
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
#  STEP 8  |  Write Continue Configuration & Rules (Pure YAML v1)
# ─────────────────────────────────────────────────────────────────

function Set-ContinueConfig {
    Write-Section "Writing Continue Configuration"

    $configDir = "$env:USERPROFILE\.continue"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    $configPath = "$configDir\config.yaml"
    $rulesPath = "$configDir\.continuerules"

    # Build YAML models block (Continue schema v1)
    $modelsYamlLines = @()
    $hasFallback = $false
    foreach ($m in $FINAL_MODELS) {
        if ($m -eq $FALLBACK_MODEL) {
            $hasFallback = $true
            $modelsYamlLines += "  - name: $m`n    provider: ollama`n    model: $m`n    roles:`n      - chat`n      - edit`n      - apply`n      - autocomplete"
        } else {
            $modelsYamlLines += "  - name: $m`n    provider: ollama`n    model: $m`n    roles:`n      - chat`n      - edit`n      - apply"
        }
    }

    if (-not $hasFallback) {
        $modelsYamlLines += "  - name: $FALLBACK_MODEL`n    provider: ollama`n    model: $FALLBACK_MODEL`n    roles:`n      - autocomplete"
    }

    # Embedding model with role: embed for @codebase RAG
    $modelsYamlLines += "  - name: $EMBEDDING_MODEL`n    provider: ollama`n    model: $EMBEDDING_MODEL`n    roles:`n      - embed"

    $modelsBlock = $modelsYamlLines -join "`n`n"

    $configYaml = @"
name: Local AI Config
version: 1.0.0
schema: v1

models:
$modelsBlock

context:
  - provider: code
  - provider: docs
  - provider: diff
  - provider: terminal
  - provider: problems
  - provider: folder
  - provider: codebase
"@

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($configPath, $configYaml, $utf8NoBom)
    Write-Log "Config written -- $configPath"

    $rulesContent = @"
# Local AI Development Rules
- Write clean, modular, modern, and well-typed code.
- Always include error handling and handle edge cases gracefully.
- Follow idioms and conventions of the target programming language.
- Do not leave unfinished placeholder comments like '// TODO' without implementation.
"@
    [System.IO.File]::WriteAllText($rulesPath, $rulesContent, $utf8NoBom)
    Write-Log "Developer rules written -- $rulesPath"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 9  |  Launch Editor & Summary
# ─────────────────────────────────────────────────────────────────

function Open-Editor {
    Write-Section "Launching Editor"
    if ($script:EDITOR_FOUND) {
        $cmd = $script:SELECTED_EDITOR.Cmd
        Write-Warn "Launching $($script:SELECTED_EDITOR.Name)..."
        try {
            Start-Process $cmd -ArgumentList "." -WindowStyle Normal
            Start-Sleep -Seconds 2
            Write-Log "$($script:SELECTED_EDITOR.Name) launched in current directory"
        } catch {
            Write-Info "Open $($script:SELECTED_EDITOR.Name) manually and open the Continue panel."
        }
    } else {
        Write-Info "Open your editor manually and open the Continue panel."
    }
}

function Show-Summary {
    Write-Section "Setup Complete"

    Write-Host "  Configured Models:" -ForegroundColor White
    $fallbackListed = $false
    foreach ($m in $FINAL_MODELS) {
        Write-Host "    • " -NoNewline -ForegroundColor Cyan
        Write-Host "$m" -NoNewline -ForegroundColor Green
        if ($m -eq $FALLBACK_MODEL) {
            $fallbackListed = $true
            Write-Host " [chat, edit, tab-autocomplete]" -ForegroundColor DarkGray
        } else {
            Write-Host " [chat, edit]" -ForegroundColor DarkGray
        }
    }
    if (-not $fallbackListed) {
        Write-Host "    • " -NoNewline -ForegroundColor Cyan
        Write-Host "$FALLBACK_MODEL" -NoNewline -ForegroundColor Green
        Write-Host " [tab-autocomplete]" -ForegroundColor DarkGray
    }

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
    if (Test-OllamaReady) {
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

    Write-Host "  Star/visit the project on GitHub? [y/N]: " -NoNewline -ForegroundColor DarkGray
    try {
        $openChoice = Read-Host
        if ($openChoice -match '^[yY]') {
            Start-Process $url
        }
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

if ([Environment]::UserInteractive) {
    try {
        Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey([System.Management.Automation.Host.ReadKeyOptions]::NoEcho -bor [System.Management.Automation.Host.ReadKeyOptions]::IncludeKeyDown)
    } catch {}
}
