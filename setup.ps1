# ──────────────────────────────────────────────────────────────────
#  AI Smart Installer  |  VSCode + Ollama + Continue  |  v2.0
#  Windows PowerShell Version
#  Author : moshiurrahmandeap11
#  License: MIT
# ──────────────────────────────────────────────────────────────────

Clear-Host
$ErrorActionPreference = "Stop"

# ── PowerShell Host Configuration ────────────────────────────────
$Host.UI.RawUI.WindowTitle = "AI Smart Installer v2.0"

# ── Color Functions ──────────────────────────────────────────────
function Write-Log   { Write-Host "  OK  " -NoNewline -ForegroundColor Green; Write-Host "  $args" -ForegroundColor White }
function Write-Warn  { Write-Host "  >>  " -NoNewline -ForegroundColor Yellow; Write-Host "  $args" -ForegroundColor White }
function Write-Error { Write-Host "  !!  " -NoNewline -ForegroundColor Red; Write-Host "  $args" -ForegroundColor White }
function Write-Info  { Write-Host "  --  " -NoNewline -ForegroundColor Cyan; Write-Host "  $args" }
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
    Write-Host "  ║           AI  SMART  INSTALLER   v2.0                  ║" -ForegroundColor Cyan
    Write-Host "  ║       VSCode  +  Ollama  +  Continue  Dev              ║" -ForegroundColor Cyan
    Write-Host "  ║                                                        ║" -ForegroundColor Cyan
    Write-Host "  ╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ─────────────────────────────────────────────────────────────────
#  STEP 1  |  Ensure Chocolatey is available
#  Chocolatey is the package manager for Windows
# ─────────────────────────────────────────────────────────────────

function Ensure-Chocolatey {
    Write-Section "Checking Chocolatey"
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Log "Chocolatey is already installed"
        return
    }

    Write-Warn "Chocolatey not found -- installing..."
    Write-Info "This requires administrator privileges"
    
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    Write-Log "Chocolatey installed successfully"
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# ─────────────────────────────────────────────────────────────────
#  STEP 2  |  Collect system hardware information
# ─────────────────────────────────────────────────────────────────

function Get-SystemInfo {
    Write-Section "System Information"

    # CPU Info
    $cpuInfo = Get-CimInstance Win32_Processor | Select-Object -First 1
    $CPU_MODEL = $cpuInfo.Name
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
    } catch {
        # GPU detection failed
    }

    # Check for NVIDIA specifically
    if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
        $nvidiaInfo = nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>$null
        if ($nvidiaInfo) {
            $nvidiaData = $nvidiaInfo -split ','
            $GPU_NAME = $nvidiaData[0].Trim()
            $GPU_VRAM = [math]::Round([int]($nvidiaData[1].Trim() -replace ' MiB','') / 1024, 1)
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

    # Return as global variables
    $script:RAM_GB = $RAM_GB
    $script:RAM_MB = $RAM_MB
    $script:CPU_CORES = $CPU_CORES
    $script:CPU_MODEL = $CPU_MODEL
    $script:GPU_VRAM = $GPU_VRAM
    $script:GPU_NAME = $GPU_NAME
    $script:DISK_FREE = $DISK_FREE
}

# ─────────────────────────────────────────────────────────────────
#  STEP 3  |  Install and start Ollama
# ─────────────────────────────────────────────────────────────────

function Install-Ollama {
    Write-Section "Ollama Installation"

    if (Get-Command ollama -ErrorAction SilentlyContinue) {
        Write-Log "Ollama is already installed"
        return
    }

    Write-Warn "Downloading Ollama installer..."
    $ollamaUrl = "https://ollama.com/download/OllamaSetup.exe"
    $installerPath = "$env:TEMP\OllamaSetup.exe"
    
    Invoke-WebRequest -Uri $ollamaUrl -OutFile $installerPath
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
    Remove-Item $installerPath -Force
    
    Write-Log "Ollama installed successfully"
}

function Start-Ollama {
    # Check if Ollama is already running
    $ollamaProcess = Get-Process ollama -ErrorAction SilentlyContinue
    if ($ollamaProcess) {
        Write-Log "Ollama server is already running"
        return
    }

    Write-Warn "Starting Ollama background server..."
    
    # Start Ollama in a hidden window
    $ollamaPath = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
    if (-not (Test-Path $ollamaPath)) {
        $ollamaPath = "ollama"
    }
    
    Start-Process -FilePath $ollamaPath -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5
    Write-Log "Ollama server started"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 4  |  VSCode + Continue extension
# ─────────────────────────────────────────────────────────────────

function Check-VSCode {
    Write-Section "VSCode + Continue Extension"

    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Error "VSCode CLI not found -- install VSCode and enable the 'code' command"
        Write-Host "  https://code.visualstudio.com/download" -ForegroundColor DarkGray
        exit 1
    }

    Write-Log "VSCode CLI found"
}

function Install-Continue {
    $extensions = code --list-extensions 2>$null
    if ($extensions -match "Continue.continue") {
        Write-Log "Continue extension is already installed"
        return
    }

    Write-Warn "Installing Continue extension..."
    code --install-extension Continue.continue
    Write-Log "Continue extension installed"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 5  |  Fetch model list from Ollama library
# ─────────────────────────────────────────────────────────────────

function Get-OllamaModels {
    Write-Section "Fetching Ollama Model Library"

    Write-Info "Connecting to ollama.com/library..."
    
    try {
        $response = Invoke-WebRequest -Uri "https://ollama.com/library" -UseBasicParsing -TimeoutSec 10
        $content = $response.Content
        
        # Extract model slugs using regex
        $pattern = 'href="/library/([^"]+)"'
        $matches = [regex]::Matches($content, $pattern)
        $OLLAMA_MODELS = ($matches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique) -join "`n"
    } catch {
        Write-Warn "Could not reach ollama.com -- using built-in model list"
        $OLLAMA_MODELS = "tinyllama`nphi`ngemma`nmistral`nllama3`ncodellama`ndeepseek-r1`nqwen2.5-coder`nllava"
    }

    $script:OLLAMA_MODELS = $OLLAMA_MODELS
    $count = ($OLLAMA_MODELS -split "`n").Count
    Write-Log "$count models fetched"
}

# ─────────────────────────────────────────────────────────────────
#  MODEL SIZE ESTIMATOR
# ─────────────────────────────────────────────────────────────────

function Get-ModelSizeGB {
    param([string]$Model)
    
    $pattern = '[\d]+\.?[\d]*(?=b)'
    $matches = [regex]::Matches($Model, $pattern, 'IgnoreCase')
    
    if ($matches.Count -eq 0) {
        return 3
    }
    
    $raw = $matches[$matches.Count - 1].Value
    $intPart = ($raw -split '\.')[0]
    
    if (-not $intPart -or [int]$intPart -eq 0) {
        $intPart = 1
    }
    
    $params = [int]$intPart
    $size = [math]::Ceiling($params * 0.55)
    
    if ($size -lt 1) { $size = 1 }
    
    return $size
}

# ─────────────────────────────────────────────────────────────────
#  STEP 6  |  Recommend compatible models based on hardware
# ─────────────────────────────────────────────────────────────────

function Show-Recommendations {
    Write-Section "Model Recommendation"

    if ($GPU_VRAM -ge 8) {
        $EFFECTIVE_MEM = $GPU_VRAM
        $MEM_SOURCE = "GPU VRAM"
    } else {
        $EFFECTIVE_MEM = $RAM_GB
        $MEM_SOURCE = "System RAM"
    }

    $MAX_MODEL_SIZE = [math]::Floor($EFFECTIVE_MEM * 0.65)
    if ($MAX_MODEL_SIZE -lt 1) { $MAX_MODEL_SIZE = 1 }

    Write-Host "  Memory Source    " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$EFFECTIVE_MEM GB  ($MEM_SOURCE)" -ForegroundColor Cyan
    
    Write-Host "  Max Model Size   " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$MAX_MODEL_SIZE GB" -ForegroundColor Yellow
    Write-Blank

    $script:FALLBACK_MODEL = "qwen2.5-coder:1.5b"
    
    $displayNames = @()
    $displaySizes = @()
    $displayTags = @()
    $modelMap = @{}
    $i = 1

    Write-Info "Filtering compatible models..."
    Write-Blank

    foreach ($model in ($OLLAMA_MODELS -split "`n")) {
        if ([string]::IsNullOrWhiteSpace($model)) { continue }
        
        $SIZE = Get-ModelSizeGB -Model $model
        
        if ($SIZE -le $MAX_MODEL_SIZE) {
            if ($SIZE -le 2) { 
                $tag = "lightweight"
                $color = "Green"
            } elseif ($SIZE -le 6) { 
                $tag = "balanced"
                $color = "Yellow"
            } else { 
                $tag = "heavy"
                $color = "Red"
            }
            
            $displayNames += $model
            $displaySizes += $SIZE
            $displayTags += @{ Text = $tag; Color = $color }
            $modelMap[$i] = $model
            $i++
        }
    }

    $script:TOTAL_AVAILABLE = $displayNames.Count
    $script:MODEL_MAP = $modelMap
    
    if ($TOTAL_AVAILABLE -eq 0) {
        Write-Warn "No models fit within your memory budget -- only fallback will be used"
    }

    # Render selection table
    Write-Host ("  {0,-5}  {1,-32}  {2,-9}  {3}" -f 'No.', 'Model', 'Size', 'Profile') -ForegroundColor White
    Write-Host ("  {0,-5}  {1,-32}  {2,-9}  {3}" -f '-----', '--------------------------------', '---------', '----------') -ForegroundColor DarkGray

    for ($j = 0; $j -lt $displayNames.Count; $j++) {
        $num = $j + 1
        Write-Host "  " -NoNewline
        Write-Host "$num)" -NoNewline -ForegroundColor Cyan
        Write-Host "  $($displayNames[$j])" -NoNewline -ForegroundColor White
        Write-Host "  ~$($displaySizes[$j]) GB" -NoNewline -ForegroundColor DarkGray
        Write-Host "  $($displayTags[$j].Text)" -ForegroundColor $displayTags[$j].Color
    }

    Write-Blank
    Write-Host "  Default Fallback   " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host $FALLBACK_MODEL -NoNewline -ForegroundColor Cyan
    Write-Host "  (autocomplete only)" -ForegroundColor DarkGray
    Write-Blank

    # Show already installed models
    Write-Host "  Already Installed:" -ForegroundColor White
    try {
        $installed = ollama list 2>$null | Select-Object -Skip 1
        if ($installed) {
            $installed | ForEach-Object { Write-Host "    $_" -ForegroundColor Green }
        } else {
            Write-Host "    None" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "    None" -ForegroundColor DarkGray
    }
    Write-Blank
}

# ─────────────────────────────────────────────────────────────────
#  STEP 7  |  Interactive model selection
# ─────────────────────────────────────────────────────────────────

function Select-Models {
    Write-Host "  Select models to install:" -ForegroundColor White
    Write-Host "  Enter row numbers separated by commas  (example:  1,3,5)" -ForegroundColor DarkGray
    Write-Host "  Press Enter to skip and use the fallback model only" -ForegroundColor DarkGray
    Write-Blank
    Write-Host "  Your choice:  " -NoNewline -ForegroundColor Cyan
    $input = Read-Host

    $script:SELECTED = @()

    if ([string]::IsNullOrWhiteSpace($input) -or $input -eq "0") {
        Write-Log "No selection -- fallback model will be used"
        return
    }

    $numbers = $input -split ',' | ForEach-Object { $_.Trim() }
    foreach ($num in $numbers) {
        if ($MODEL_MAP.ContainsKey([int]$num)) {
            $script:SELECTED += $MODEL_MAP[[int]$num]
        } else {
            Write-Warn "Invalid entry: $num -- skipped"
        }
    }
}

# ─────────────────────────────────────────────────────────────────
#  STEP 8  |  Pull selected models from Ollama registry
# ─────────────────────────────────────────────────────────────────

function Install-SelectedModels {
    Write-Section "Downloading Selected Models"

    if ($SELECTED.Count -eq 0) {
        Write-Log "No additional models to download"
        return
    }

    foreach ($m in $SELECTED) {
        try {
            $installed = ollama list 2>$null | Select-String $m
            if ($installed) {
                Write-Log "$m -- already installed"
            } else {
                Write-Warn "Pulling $m ..."
                ollama pull $m
                Write-Log "$m -- installed"
            }
        } catch {
            Write-Warn "Pulling $m ..."
            ollama pull $m
            Write-Log "$m -- installed"
        }
    }
}

# ─────────────────────────────────────────────────────────────────
#  STEP 9  |  Guarantee the fallback model is present
# ─────────────────────────────────────────────────────────────────

function Install-Fallback {
    Write-Section "Fallback Model"

    if (-not $FALLBACK_MODEL) {
        $script:FALLBACK_MODEL = "qwen2.5-coder:1.5b"
    }

    try {
        $installed = ollama list 2>$null | Select-String $FALLBACK_MODEL
        if ($installed) {
            Write-Log "$FALLBACK_MODEL -- already installed"
        } else {
            Write-Warn "Installing fallback -- $FALLBACK_MODEL ..."
            ollama pull $FALLBACK_MODEL
            Write-Log "$FALLBACK_MODEL -- installed"
        }
    } catch {
        Write-Warn "Installing fallback -- $FALLBACK_MODEL ..."
        ollama pull $FALLBACK_MODEL
        Write-Log "$FALLBACK_MODEL -- installed"
    }
}

# ─────────────────────────────────────────────────────────────────
#  Build final model list
# ─────────────────────────────────────────────────────────────────

function Build-FinalModels {
    $script:FINAL_MODELS = @()
    
    if ($SELECTED.Count -gt 0) {
        $script:FINAL_MODELS = $SELECTED
    }

    $found = $FINAL_MODELS -contains $FALLBACK_MODEL
    if (-not $found) {
        $script:FINAL_MODELS += $FALLBACK_MODEL
    }
}

# ─────────────────────────────────────────────────────────────────
#  STEP 10  |  Write the Continue extension configuration
# ─────────────────────────────────────────────────────────────────

function Set-ContinueConfig {
    Write-Section "Writing Continue Configuration"

    $configDir = "$env:USERPROFILE\.continue"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    $configPath = "$configDir\config.json"
    
    $modelsConfig = @()
    foreach ($m in $FINAL_MODELS) {
        if ($m -eq $FALLBACK_MODEL) {
            $modelsConfig += @{
                name = $m
                provider = "ollama"
                model = $m
                roles = @("autocomplete")
            }
        } else {
            $modelsConfig += @{
                name = $m
                provider = "ollama"
                model = $m
                roles = @("chat", "autocomplete")
            }
        }
    }

    $config = @{
        name = "Local AI Config"
        version = "1.0.0"
        schema = "v1"
        models = $modelsConfig
        context = @(
            @{ provider = "code" },
            @{ provider = "docs" },
            @{ provider = "diff" },
            @{ provider = "terminal" },
            @{ provider = "problems" },
            @{ provider = "folder" },
            @{ provider = "codebase" }
        )
        tabAutocomplete = @{
            disable = $false
        }
        slashCommands = @(
            @{ name = "edit"; description = "Edit selected code" },
            @{ name = "comment"; description = "Add comments to code" },
            @{ name = "share"; description = "Export conversation" },
            @{ name = "cmd"; description = "Generate a shell command" }
        )
    }

    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
    Write-Log "Config written -- $configPath"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 11  |  Launch VSCode in the current directory
# ─────────────────────────────────────────────────────────────────

function Open-VSCode {
    Write-Section "Launching VSCode"
    Write-Warn "Opening VSCode..."
    Start-Process code -ArgumentList "." -WindowStyle Normal
    Start-Sleep -Seconds 2
    Write-Log "VSCode launched"
}

# ─────────────────────────────────────────────────────────────────
#  STEP 12  |  Print installation summary
# ─────────────────────────────────────────────────────────────────

function Show-Summary {
    Write-Section "Setup Complete"

    Write-Host "  Configured Models:" -ForegroundColor White
    foreach ($m in $FINAL_MODELS) {
        if ($m -eq $FALLBACK_MODEL) {
            Write-Host "  " -NoNewline
            Write-Host "  $m" -NoNewline -ForegroundColor Green
            Write-Host "  [autocomplete]" -ForegroundColor DarkGray
        } else {
            Write-Host "  " -NoNewline
            Write-Host "  $m" -NoNewline -ForegroundColor Green
            Write-Host "  [chat, autocomplete]" -ForegroundColor DarkGray
        }
    }

    Write-Blank
    Write-Host "  Config File    " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$env:USERPROFILE\.continue\config.json" -ForegroundColor DarkGray

    Write-Host "  Ollama Status  " -NoNewline -ForegroundColor White
    Write-Host "|  " -NoNewline -ForegroundColor DarkGray
    
    $ollamaRunning = Get-Process ollama -ErrorAction SilentlyContinue
    if ($ollamaRunning) {
        Write-Host "Running" -ForegroundColor Green
    } else {
        Write-Host "Not Running" -ForegroundColor Red
    }
    
    Write-Blank
    Write-Host "  Open VSCode  ->  Continue panel  ->  Start coding with AI" -ForegroundColor Yellow
    Write-Blank
}

# ─────────────────────────────────────────────────────────────────
#  STEP 13  |  Open the developer GitHub profile in the browser
# ─────────────────────────────────────────────────────────────────

function Open-GitHub {
    $url = "https://github.com/moshiurrahmandeap11"

    Write-Blank
    Write-Host "  ╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                        ║" -ForegroundColor Cyan
    Write-Host "  ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "  Thanks for using AI Smart Installer                " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "  ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "  Developer  :  github.com/moshiurrahmandeap11       " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "  ║                                                        ║" -ForegroundColor Cyan
    Write-Host "  ╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Blank

    Start-Process $url
}

# ─────────────────────────────────────────────────────────────────
#  ENTRY POINT  |  Run all installer steps in sequence
# ─────────────────────────────────────────────────────────────────

# Check for administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "  !!  " -NoNewline -ForegroundColor Red
    Write-Host "This script requires Administrator privileges" -ForegroundColor White
    Write-Host "  --  " -NoNewline -ForegroundColor Cyan
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor White
    Start-Sleep -Seconds 3
    exit 1
}

# Run all steps
Show-Banner
Ensure-Chocolatey
Get-SystemInfo
Install-Ollama
Start-Ollama
Check-VSCode
Install-Continue
Get-OllamaModels
Show-Recommendations
Select-Models
Install-SelectedModels
Install-Fallback
Build-FinalModels
Set-ContinueConfig
Open-VSCode
Show-Summary
Open-GitHub

Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")