# ------------------------------------------------------------------
#  Just One  |  Local AI Automator  |  v2.5
#  Windows PowerShell Version
#  Author  : Moshiur Rahman Deap
#  Website : https://one.moshiur.pro  |  https://moshiur.pro
#  Github  : https://github.com/moshiurrahmandeap11
#  LinkedIn: https://linkedin.com/in/moshiurrahmandeap
#  License : MIT
# ------------------------------------------------------------------

if ($Host.Name -eq 'ConsoleHost') {
    try { Clear-Host } catch {}
}
$ErrorActionPreference = "Stop"

# Enable UTF-8 output for crisp box-drawing & block-art glyphs
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# Ensure execution policy allows script execution for CurrentUser
try {
    $currentUserPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
    if ($currentUserPolicy -notin @('RemoteSigned', 'Unrestricted', 'Bypass')) {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
    }
} catch {}

try { $Host.UI.RawUI.WindowTitle = "Just One v2.5 | Moshiur Rahman Deap" } catch {}

# -- Unicode Box & Block Glyphs (codepoints keep source 100% pure ASCII) --
$script:G_TL    = [string][char]0x256D  # rounded top-left
$script:G_TR    = [string][char]0x256E  # rounded top-right
$script:G_BL    = [string][char]0x2570  # rounded bottom-left
$script:G_BR    = [string][char]0x256F  # rounded bottom-right
$script:G_H     = [string][char]0x2500  # horizontal line
$script:G_V     = [string][char]0x2502  # vertical line
$script:G_FULL  = [string][char]0x2588  # full block
$script:G_SHADE = [string][char]0x2591  # light shade
$script:G_DH    = [string][char]0x2550  # double horizontal
$script:G_DQ    = [string][char]0x2554  # double top-left
$script:G_DW    = [string][char]0x2557  # double top-right
$script:G_DV    = [string][char]0x2551  # double vertical
$script:G_DL    = [string][char]0x255A  # double bottom-left
$script:G_DR    = [string][char]0x255D  # double bottom-right
$script:G_PTR   = ">"

# -- UI Helpers (Strictly Emoji-Free) ------------------------------
$script:TOTAL_STEPS = 8
$script:BOX_INNER = 64

function Write-Log   { Write-Host "  [OK] " -NoNewline -ForegroundColor Green;  Write-Host "$args" -ForegroundColor White }
function Write-Warn  { Write-Host "  [>>] " -NoNewline -ForegroundColor Yellow; Write-Host "$args" -ForegroundColor Yellow }
function Write-Err   { Write-Host "  [!!] " -NoNewline -ForegroundColor Red;    Write-Host "$args" -ForegroundColor Red }
function Write-Info  { Write-Host "  [--] " -NoNewline -ForegroundColor Cyan;   Write-Host "$args" -ForegroundColor Gray }
function Write-Blank { Write-Host "" }

function Expand-BlockArt {
    param([string]$Template)
    return $Template.Replace('B', $script:G_FULL).Replace('Q', $script:G_DQ).Replace('E', $script:G_DH).Replace('W', $script:G_DW).Replace('V', $script:G_DV).Replace('L', $script:G_DL).Replace('R', $script:G_DR)
}

function Write-CardLine {
    param(
        [string]$Label,
        [string]$Value,
        [string]$Extra = "",
        [string]$ValueColor = "Cyan",
        [string]$BorderColor = "DarkCyan"
    )
    $inner = $script:BOX_INNER
    $prefix = "  $Label"
    $mid = " | "
    $body = "$prefix$mid$Value$Extra"
    $pad = [math]::Max(1, $inner - $body.Length)
    Write-Host "  $($script:G_V)" -NoNewline -ForegroundColor $BorderColor
    Write-Host $prefix -NoNewline -ForegroundColor Gray
    Write-Host $mid -NoNewline -ForegroundColor DarkGray
    Write-Host $Value -NoNewline -ForegroundColor $ValueColor
    if ($Extra) { Write-Host $Extra -NoNewline -ForegroundColor DarkGray }
    Write-Host (" " * $pad) -NoNewline
    Write-Host "$($script:G_V)" -ForegroundColor $BorderColor
}

function Write-Step {
    param(
        [int]$Step,
        [string]$Title
    )
    $badge = "STEP 0$Step/0$($script:TOTAL_STEPS)"
    $headerText = " $badge :: $Title "
    $fillCount = [math]::Max(4, ($script:BOX_INNER + 2) - $headerText.Length - 2)
    $fill = $script:G_H * $fillCount
    Write-Blank
    Write-Host "  $($script:G_TL)$($script:G_H) " -NoNewline -ForegroundColor DarkCyan
    Write-Host $badge -NoNewline -ForegroundColor Cyan
    Write-Host " :: " -NoNewline -ForegroundColor DarkGray
    Write-Host $Title -NoNewline -ForegroundColor White
    Write-Host " $fill" -ForegroundColor DarkCyan
    Write-Blank
}

function Show-Banner {
    $logo = @(
        @{ T = "     BBW BBW   BBW BBBBBBBW BBBBBBBBW   BBBBBBW  BBBW   BBW BBBBBBBW"; C = "Cyan" },
        @{ T = "     BBV BBV   BBV BBQEEEER LEEBBQEER  BBQEEEBBW BBBBW  BBV BBQEEEER"; C = "Cyan" },
        @{ T = "     BBV BBV   BBV BBBBBBBW    BBV     BBV   BBV BBQBBW BBV BBBBBW  "; C = "White" },
        @{ T = "BB   BBV BBV   BBV LEEEEBBV    BBV     BBV   BBV BBVLBBWBBV BBQEEER "; C = "White" },
        @{ T = "LBBBBBQR LBBBBBBQR BBBBBBBV    BBV     LBBBBBBQR BBV LBBBBV BBBBBBBW"; C = "Green" },
        @{ T = " LEEEER   LEEEEER  LEEEEEER    LER      LEEEEER  LER  LEEER LEEEEER "; C = "Green" }
    )

    Write-Blank
    foreach ($row in $logo) {
        Write-Host ("  " + (Expand-BlockArt $row.T)) -ForegroundColor $row.C
    }

    $inner = $script:BOX_INNER
    $border = $script:G_H * $inner
    $line1 = "  LOCAL AI & CODEBASE RAG AUTOMATOR  |  VERSION 2.5"
    $line2 = "  Created by Moshiur Rahman Deap     |  one.moshiur.pro"

    Write-Blank
    Write-Host "  $($script:G_TL)$border$($script:G_TR)" -ForegroundColor DarkCyan
    Write-Host "  $($script:G_V)" -NoNewline -ForegroundColor DarkCyan
    Write-Host $line1 -NoNewline -ForegroundColor White
    Write-Host (" " * [math]::Max(0, $inner - $line1.Length)) -NoNewline
    Write-Host "$($script:G_V)" -ForegroundColor DarkCyan

    Write-Host "  $($script:G_V)" -NoNewline -ForegroundColor DarkCyan
    Write-Host $line2 -NoNewline -ForegroundColor Cyan
    Write-Host (" " * [math]::Max(0, $inner - $line2.Length)) -NoNewline
    Write-Host "$($script:G_V)" -ForegroundColor DarkCyan
    Write-Host "  $($script:G_BL)$border$($script:G_BR)" -ForegroundColor DarkCyan
    Write-Blank
}

function Show-BudgetBar {
    param(
        [double]$BudgetGB,
        [double]$TotalGB,
        [string]$Source
    )
    $barWidth = 24
    $ratio = if ($TotalGB -gt 0) { [math]::Min(1.0, $BudgetGB / $TotalGB) } else { 0.65 }
    $filled = [math]::Round($barWidth * $ratio)
    $empty = $barWidth - $filled
    $bar = ($script:G_FULL * $filled) + ($script:G_SHADE * $empty)

    $inner = $script:BOX_INNER
    $topTitle = "$($script:G_H) MEMORY SAFETY GUARD "
    $topFill = $script:G_H * ($inner - $topTitle.Length)

    Write-Host "  $($script:G_TL)$topTitle$topFill$($script:G_TR)" -ForegroundColor DarkCyan
    Write-CardLine -Label "Memory Source " -Value "$TotalGB GB" -Extra " ($Source)" -ValueColor "Cyan"
    Write-CardLine -Label "Safe AI Budget" -Value "[$bar] $BudgetGB GB" -Extra " (65% Limit)" -ValueColor "Green"
    Write-Host "  $($script:G_BL)$($script:G_H * $inner)$($script:G_BR)" -ForegroundColor DarkCyan
    Write-Blank
}

function Invoke-SpinnerWait {
    param(
        [string]$Label,
        [scriptblock]$Condition,
        [int]$TimeoutSec = 20
    )
    $frames = @('[|]', '[/]', '[-]', '[\]')
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $idx = 0

    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        if (& $Condition) {
            if ($Host.Name -eq 'ConsoleHost') {
                Write-Host "`r$(' ' * 72)`r" -NoNewline
            }
            return $true
        }
        $f = $frames[$idx % $frames.Count]
        if ($Host.Name -eq 'ConsoleHost') {
            Write-Host "`r  $f $Label..." -NoNewline -ForegroundColor Cyan
        }
        $idx++
        Start-Sleep -Milliseconds 120
    }

    if ($Host.Name -eq 'ConsoleHost') {
        Write-Host "`r$(' ' * 72)`r" -NoNewline
    }
    return $false
}

function Read-RegistryUtf16String {
    param($Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [byte[]]) {
        $decoded = [System.Text.Encoding]::Unicode.GetString($Value).TrimEnd([char]0).Trim()
        if ($decoded) { return $decoded }
        return $null
    }
    $str = ([string]$Value).Trim()
    if ($str) { return $str }
    return $null
}

# -----------------------------------------------------------------
#  STEP 1  |  Collect system hardware information
# -----------------------------------------------------------------

function Get-SystemInfo {
    Write-Step 1 "System Hardware & Memory Profile"

    $CPU_MODEL = "Unknown CPU"
    $CPU_CORES = [Environment]::ProcessorCount
    try {
        $cpuInfo = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
        if ($cpuInfo -and $cpuInfo.Name) { $CPU_MODEL = $cpuInfo.Name.Trim() }
        if ($cpuInfo -and $cpuInfo.NumberOfLogicalProcessors) { $CPU_CORES = [int]$cpuInfo.NumberOfLogicalProcessors }
    } catch {}

    $RAM_GB = 8.0
    $RAM_MB = 8192
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        if ($os -and $os.TotalVisibleMemorySize) {
            $RAM_GB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            $RAM_MB = [math]::Round($os.TotalVisibleMemorySize / 1KB, 0)
        }
    } catch {}

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
                        $descName = Read-RegistryUtf16String $adapter.DriverDesc
                        $chipName = Read-RegistryUtf16String $adapter.'HardwareInformation.AdapterString'
                        if ($descName) {
                            $GPU_NAME = $descName
                        } elseif ($chipName) {
                            $GPU_NAME = $chipName
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

    $DISK_FREE = 0.0
    try {
        $driveName = (Get-Location).Drive.Name
        if (-not $driveName -or -not (Get-PSDrive -Name $driveName -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
            $driveName = $env:SystemDrive.TrimEnd(':')
        }
        $disk = Get-PSDrive -Name $driveName -PSProvider FileSystem -ErrorAction Stop
        $DISK_FREE = [math]::Round($disk.Free / 1GB, 1)
    } catch {}

    # Truncate long hardware names so card frame stays aligned
    $cpuDisp = if ($CPU_MODEL.Length -gt 35) { $CPU_MODEL.Substring(0, 32) + "..." } else { $CPU_MODEL }
    $gpuDisp = if ($GPU_NAME.Length -gt 35) { $GPU_NAME.Substring(0, 32) + "..." } else { $GPU_NAME }

    $inner = $script:BOX_INNER
    $topTitle = "$($script:G_H) HARDWARE TELEMETRY "
    $topFill = $script:G_H * ($inner - $topTitle.Length)
    Write-Host "  $($script:G_TL)$topTitle$topFill$($script:G_TR)" -ForegroundColor DarkCyan
    Write-CardLine -Label "CPU      " -Value $cpuDisp -Extra " ($CPU_CORES threads)"
    Write-CardLine -Label "RAM      " -Value "$RAM_GB GB" -Extra " ($RAM_MB MB)"
    Write-CardLine -Label "GPU      " -Value $gpuDisp -Extra " ($GPU_VRAM GB)"
    Write-CardLine -Label "Disk Free" -Value "$DISK_FREE GB"
    Write-Host "  $($script:G_BL)$($script:G_H * $inner)$($script:G_BR)" -ForegroundColor DarkCyan

    if ($DISK_FREE -gt 0 -and $DISK_FREE -lt 8) {
        Write-Blank
        Write-Warn "Low disk space ($DISK_FREE GB). Recommend at least 8 GB free for AI models."
    }

    $script:RAM_GB = $RAM_GB
    $script:RAM_MB = $RAM_MB
    $script:CPU_CORES = $CPU_CORES
    $script:CPU_MODEL = $CPU_MODEL
    $script:GPU_VRAM = $GPU_VRAM
    $script:GPU_NAME = $GPU_NAME
    $script:DISK_FREE = $DISK_FREE

    if ($GPU_VRAM -ge 8) {
        $script:EFFECTIVE_MEM = $GPU_VRAM
        $script:MEM_SOURCE = "Dedicated GPU VRAM"
    } else {
        $script:EFFECTIVE_MEM = $RAM_GB
        $script:MEM_SOURCE = "System RAM"
    }
}

# -----------------------------------------------------------------
#  STEP 2  |  Configure Ollama Optimizations & Install/Start
# -----------------------------------------------------------------

function Configure-OllamaOptimization {
    $prevFlash = [System.Environment]::GetEnvironmentVariable("OLLAMA_FLASH_ATTENTION", "User")
    $prevKeep = [System.Environment]::GetEnvironmentVariable("OLLAMA_KEEP_ALIVE", "User")
    $script:OLLAMA_ENV_CHANGED = ($prevFlash -ne "1" -or $prevKeep -ne "24h")

    try {
        [System.Environment]::SetEnvironmentVariable("OLLAMA_FLASH_ATTENTION", "1", "User")
        [System.Environment]::SetEnvironmentVariable("OLLAMA_KEEP_ALIVE", "24h", "User")
        $env:OLLAMA_FLASH_ATTENTION = "1"
        $env:OLLAMA_KEEP_ALIVE = "24h"
        Write-Log "Optimizations enabled: Flash Attention + 24h Model Keep-Alive"
    } catch {
        $env:OLLAMA_FLASH_ATTENTION = "1"
        $env:OLLAMA_KEEP_ALIVE = "24h"
        Write-Warn "Applied Ollama optimizations for current session."
    }
}

function Get-OllamaPath {
    $ollamaExe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
    if (Test-Path $ollamaExe) { return $ollamaExe }
    $command = Get-Command ollama -ErrorAction SilentlyContinue
    if ($command) { return $command.Path }
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

function Setup-Ollama {
    Write-Step 2 "Ollama Runtime & GPU Acceleration"
    Configure-OllamaOptimization

    $ollamaPath = Get-OllamaPath
    if ($ollamaPath) {
        Write-Log "Ollama binary ready ($ollamaPath)"
    } else {
        Write-Info "Downloading Ollama installer..."
        $ollamaUrl = "https://ollama.com/download/OllamaSetup.exe"
        $installerPath = "$env:TEMP\OllamaSetup.exe"
        try {
            Invoke-WebRequest -Uri $ollamaUrl -OutFile $installerPath -UseBasicParsing
            $proc = Start-Process -FilePath $installerPath -ArgumentList "/S" -PassThru
            $null = Invoke-SpinnerWait -Label "Installing Ollama" -Condition { $proc.HasExited } -TimeoutSec 180
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
            Write-Log "Ollama installed successfully"
        } catch {
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
            Write-Err "Failed to download or install Ollama: $($_.Exception.Message)"
            exit 1
        }
    }

    if ((Test-OllamaReady) -and (-not $script:OLLAMA_ENV_CHANGED)) {
        Write-Log "Ollama API server is online (127.0.0.1:11434)"
        return
    }

    if ($script:OLLAMA_ENV_CHANGED -and (Get-Process ollama -ErrorAction SilentlyContinue)) {
        Write-Info "Refreshing Ollama server to apply new GPU optimizations..."
        Get-Process -Name "ollama*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 800
    }

    $ollamaPath = Get-OllamaPath
    if (-not $ollamaPath) {
        Write-Err "Ollama executable not found. Please restart your terminal and run again."
        exit 1
    }

    if (-not (Get-Process ollama -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath $ollamaPath -ArgumentList "serve" -WindowStyle Hidden
    }

    $ready = Invoke-SpinnerWait -Label "Waiting for Ollama API server" -Condition { Test-OllamaReady } -TimeoutSec 20
    if ($ready) {
        Write-Log "Ollama API server is online (127.0.0.1:11434)"
    } else {
        Write-Warn "Ollama server started; API is still warming up."
    }
}

# -----------------------------------------------------------------
#  STEP 3  |  Multi-Editor Detection & Continue Extension
# -----------------------------------------------------------------

function Setup-Editors {
    Write-Step 3 "Code Editors & Continue Extension"

    $candidates = @(
        @{ Name = "VS Code"; Cmd = "code" },
        @{ Name = "Cursor"; Cmd = "cursor" },
        @{ Name = "VS Code Insiders"; Cmd = "code-insiders" },
        @{ Name = "VSCodium"; Cmd = "codium" }
    )

    $script:DETECTED_EDITORS = @()
    foreach ($ed in $candidates) {
        if (Get-Command $ed.Cmd -ErrorAction SilentlyContinue) {
            $script:DETECTED_EDITORS += $ed
        }
    }

    if ($script:DETECTED_EDITORS.Count -eq 0) {
        Write-Warn "No supported editor CLI found on PATH (checked code, cursor, code-insiders, codium)."
        if ((Get-Command winget -ErrorAction SilentlyContinue) -and [Environment]::UserInteractive -and ($env:JUST_ONE_AUTO -ne "1")) {
            Write-Host "  [--] Auto-install VS Code via winget? [y/N]: " -NoNewline -ForegroundColor Cyan
            try {
                $ans = Read-Host
                if ($ans -match '^[yY]') {
                    & winget install -e --id Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                    if (Get-Command code -ErrorAction SilentlyContinue) {
                        $script:DETECTED_EDITORS += @{ Name = "VS Code"; Cmd = "code" }
                    }
                }
            } catch {}
        }
    }

    if ($script:DETECTED_EDITORS.Count -eq 0) {
        Write-Info "Config will still be generated; open VS Code or Cursor anytime to use it."
        return
    }

    foreach ($ed in $script:DETECTED_EDITORS) {
        $cmd = $ed.Cmd
        try {
            $extensions = & $cmd --list-extensions 2>$null
            if ($extensions -match "Continue\.continue") {
                Write-Log "$($ed.Name) detected -- Continue extension ready"
            } else {
                Write-Info "Installing Continue extension in $($ed.Name)..."
                & $cmd --install-extension Continue.continue | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "$($ed.Name) detected -- Continue extension installed"
                } else {
                    Write-Warn "$($ed.Name) detected -- auto-install returned code $LASTEXITCODE (install Continue manually)"
                }
            }
        } catch {
            Write-Warn "$($ed.Name) detected -- could not query/install extension"
        }
    }
}

# -----------------------------------------------------------------
#  STEP 4  |  Model Catalog & Size Estimation
# -----------------------------------------------------------------

function Get-OllamaModels {
    Write-Step 4 "Live Ollama Model Catalog"

    $loaded = $false
    try {
        $response = Invoke-WebRequest -Uri "https://ollama.com/library" -UseBasicParsing -TimeoutSec 8
        $pattern = 'href="/library/([a-zA-Z0-9_.:-]+)"'
        $rxMatches = [regex]::Matches($response.Content, $pattern)
        $familyList = $rxMatches | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ } | Sort-Object -Unique
        if ($familyList -and $familyList.Count -gt 0) {
            $OLLAMA_MODELS = $familyList -join "`n"
            $loaded = $true
        }
    } catch {}

    if (-not $loaded) {
        Write-Warn "Could not reach ollama.com -- using built-in curated catalog"
        $OLLAMA_MODELS = "deepseek-r1`nqwen2.5-coder`nllama3.2`nllama3.1`nmistral`ncodellama`nphi4`ngemma2`nllava"
    }

    $script:OLLAMA_MODELS = $OLLAMA_MODELS
    $count = ($OLLAMA_MODELS -split "`n").Count
    Write-Log "$count model families ready for hardware filtering"
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

    if ($Model -match "qwq")          { return 18 }
    if ($Model -match "phi4")         { return 9 }
    if ($Model -match "gemma2")       { return 6 }
    if ($Model -match "llama3\.2")    { return 2 }
    if ($Model -match "llama3\.1|llama3\.3|mistral|codellama|llava|qwen2\.5-coder|deepseek-r1") { return 5 }
    return 4
}

function Get-ModelTag {
    param([string]$Model)

    if ($Model -match "coder|code|starcoder")   { return "Coder" }
    if ($Model -match "deepseek-r1|qwq")        { return "Reasoning" }
    if ($Model -match "llava|vision|minicpm-v") { return "Vision" }
    return "General"
}

# -----------------------------------------------------------------
#  STEP 5  |  Interactive Mode Picker (Strict Fixed-Width Alignment)
# -----------------------------------------------------------------

function Render-ModeBox {
    param([int]$SelectedChoice, [string]$HintText)
    $inner = $script:BOX_INNER
    $border = $script:G_H * $inner

    $opt1 = if ($SelectedChoice -eq 1) { "  > [1] Express Auto Setup   | Recommended for your specs" } else { "    [1] Express Auto Setup   | Recommended for your specs" }
    $opt2 = if ($SelectedChoice -eq 2) { "  > [2] Custom Model Picker  | Pick from live Ollama catalog" } else { "    [2] Custom Model Picker  | Pick from live Ollama catalog" }

    $pad1 = " " * [math]::Max(0, $inner - $opt1.Length)
    $pad2 = " " * [math]::Max(0, $inner - $opt2.Length)

    Write-Host "  $($script:G_TL)$border$($script:G_TR)" -ForegroundColor DarkCyan
    Write-Host "  $($script:G_V)" -NoNewline -ForegroundColor DarkCyan
    Write-Host "$opt1$pad1" -NoNewline -ForegroundColor $(if ($SelectedChoice -eq 1) { "Cyan" } else { "DarkGray" })
    Write-Host "$($script:G_V)" -ForegroundColor DarkCyan

    Write-Host "  $($script:G_V)" -NoNewline -ForegroundColor DarkCyan
    Write-Host "$opt2$pad2" -NoNewline -ForegroundColor $(if ($SelectedChoice -eq 2) { "Yellow" } else { "DarkGray" })
    Write-Host "$($script:G_V)" -ForegroundColor DarkCyan
    Write-Host "  $($script:G_BL)$border$($script:G_BR)" -ForegroundColor DarkCyan
    Write-Host ("  " + $HintText + (" " * [math]::Max(0, 62 - $HintText.Length))) -ForegroundColor White
}

function Show-ModeSelector {
    $script:SELECTED = @()
    $script:FALLBACK_MODEL = "qwen2.5-coder:1.5b"
    $script:EMBEDDING_MODEL = "nomic-embed-text"

    $MAX_MODEL_SIZE = [math]::Floor($EFFECTIVE_MEM * 0.65)
    if ($MAX_MODEL_SIZE -lt 1) { $MAX_MODEL_SIZE = 1 }

    Write-Step 5 "Model Setup Mode"
    Show-BudgetBar -BudgetGB $MAX_MODEL_SIZE -TotalGB $EFFECTIVE_MEM -Source $MEM_SOURCE

    $choice = 1
    $canInteractive = ($Host.Name -eq 'ConsoleHost') -and [Environment]::UserInteractive -and (-not [Console]::IsInputRedirected)

    if ($env:JUST_ONE_AUTO -eq "1" -or (-not $canInteractive)) {
        $choice = 1
    } else {
        Write-Host "  Select installation mode:" -ForegroundColor White
        Write-Blank

        Render-ModeBox -SelectedChoice 1 -HintText "Use Up/Down or 1/2 to choose, then press [Enter]"
        $endRow = [Console]::CursorTop
        $boxTopRow = [math]::Max(0, $endRow - 5)

        while ($true) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            if ($key.VirtualKeyCode -eq 38 -or $key.Character -eq '1') {
                $choice = 1
            } elseif ($key.VirtualKeyCode -eq 40 -or $key.Character -eq '2') {
                $choice = 2
            } elseif ($key.Character -eq 'c' -or $key.Character -eq 'C') {
                $choice = 2
                try {
                    [Console]::SetCursorPosition(0, $boxTopRow)
                    Render-ModeBox -SelectedChoice $choice -HintText "Selected [2] Custom Model Picker"
                } catch {}
                break
            } elseif ($key.VirtualKeyCode -eq 13) {
                try {
                    [Console]::SetCursorPosition(0, $boxTopRow)
                    Render-ModeBox -SelectedChoice $choice -HintText "Confirmed [$choice]"
                } catch {}
                break
            } else {
                continue
            }

            try {
                [Console]::SetCursorPosition(0, $boxTopRow)
                Render-ModeBox -SelectedChoice $choice -HintText "Selected [$choice] -- press [Enter] to confirm"
            } catch {}
        }
        Write-Blank
    }

    if ($choice -eq 1) {
        if ($EFFECTIVE_MEM -ge 24) {
            $script:SELECTED = @("qwen2.5-coder:14b", "deepseek-r1:8b")
        } elseif ($EFFECTIVE_MEM -ge 12) {
            $script:SELECTED = @("qwen2.5-coder:7b", "deepseek-r1:7b")
        } elseif ($EFFECTIVE_MEM -ge 8) {
            $script:SELECTED = @("qwen2.5-coder:7b")
        } else {
            $script:SELECTED = @("qwen2.5-coder:3b")
        }
        Write-Log "Express Preset ($EFFECTIVE_MEM GB $MEM_SOURCE): $($script:SELECTED -join ', ')"
        return
    }

    # Custom Model Table
    $displayNames = @()
    $displaySizes = @()
    $displayTags = @()
    $modelMap = @{}
    $i = 1

    foreach ($model in ($OLLAMA_MODELS -split "`n")) {
        if ([string]::IsNullOrWhiteSpace($model)) { continue }
        $SIZE = Get-ModelSizeGB -Model $model
        if ($SIZE -le $MAX_MODEL_SIZE) {
            $displayNames += $model
            $displaySizes += $SIZE
            $displayTags += (Get-ModelTag -Model $model)
            $modelMap[$i] = $model
            $i++
        }
    }

    Write-Host ("  {0,-4}  {1,-28}  {2,-9}  {3}" -f 'No.', 'Model Family', 'Est.Size', 'Role') -ForegroundColor White
    Write-Host ("  {0,-4}  {1,-28}  {2,-9}  {3}" -f '----', '----------------------------', '---------', '--------') -ForegroundColor DarkGray

    for ($j = 0; $j -lt $displayNames.Count; $j++) {
        $num = $j + 1
        Write-Host "  " -NoNewline
        Write-Host ("{0,2})" -f $num) -NoNewline -ForegroundColor Cyan
        Write-Host ("  {0,-28}" -f $displayNames[$j]) -NoNewline -ForegroundColor White
        Write-Host ("~{0,-2} GB    " -f $displaySizes[$j]) -NoNewline -ForegroundColor DarkGray
        Write-Host "[$($displayTags[$j])]" -ForegroundColor Yellow
    }

    Write-Blank
    Write-Info "Enter comma-separated numbers (e.g. 1,3), or press Enter for default fallback."
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

# -----------------------------------------------------------------
#  STEP 6  |  Download Models (Selected + Fallback + Embedding)
# -----------------------------------------------------------------

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
    Write-Step 6 "Downloading AI & Embedding Models"

    $ollamaPath = Get-OllamaPath
    if (-not $ollamaPath) {
        Write-Err "Ollama executable not found. Please restart your terminal and run again."
        exit 1
    }

    $script:SUCCESSFUL_MODELS = @()

    foreach ($m in $SELECTED) {
        try {
            if (Test-OllamaModelInstalled -OllamaPath $ollamaPath -ModelName $m) {
                Write-Log "$m -- already installed"
                $script:SUCCESSFUL_MODELS += $m
            } else {
                Write-Info "Pulling $m ..."
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

    Write-Blank
    if (Test-OllamaModelInstalled -OllamaPath $ollamaPath -ModelName $FALLBACK_MODEL) {
        Write-Log "$FALLBACK_MODEL [tab-autocomplete] -- already installed"
    } else {
        Write-Info "Pulling tab-autocomplete model: $FALLBACK_MODEL ..."
        try {
            & $ollamaPath pull $FALLBACK_MODEL
            if ($LASTEXITCODE -eq 0) {
                Write-Log "$FALLBACK_MODEL [tab-autocomplete] -- installed"
            } else {
                Write-Warn "Could not pull $FALLBACK_MODEL"
            }
        } catch {
            Write-Warn "Could not pull $FALLBACK_MODEL"
        }
    }

    if (Test-OllamaModelInstalled -OllamaPath $ollamaPath -ModelName $EMBEDDING_MODEL) {
        Write-Log "$EMBEDDING_MODEL [@codebase RAG] -- already installed"
    } else {
        Write-Info "Pulling embedding model: $EMBEDDING_MODEL (274 MB) ..."
        try {
            & $ollamaPath pull $EMBEDDING_MODEL
            if ($LASTEXITCODE -eq 0) {
                Write-Log "$EMBEDDING_MODEL [@codebase RAG] -- installed"
            } else {
                Write-Warn "Could not pull $EMBEDDING_MODEL"
            }
        } catch {
            Write-Warn "Could not pull $EMBEDDING_MODEL"
        }
    }

    $script:FINAL_MODELS = @()
    if ($script:SUCCESSFUL_MODELS.Count -gt 0) {
        $script:FINAL_MODELS = $script:SUCCESSFUL_MODELS
    } else {
        $script:FINAL_MODELS += $FALLBACK_MODEL
    }
}

# -----------------------------------------------------------------
#  STEP 7  |  Backup & Write Continue Configuration (Pure YAML v1)
# -----------------------------------------------------------------

function Set-ContinueConfig {
    Write-Step 7 "Writing Continue Config & Rules"

    $configDir = "$env:USERPROFILE\.continue"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    $configPath = "$configDir\config.yaml"
    $rulesPath = "$configDir\.continuerules"
    $script:BACKUP_PATH = $null

    if (Test-Path $configPath) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backup = "$configDir\config.yaml.bak.$stamp"
        try {
            Copy-Item -Path $configPath -Destination $backup -Force
            $script:BACKUP_PATH = $backup
            Write-Info "Existing config backed up -> $backup"
        } catch {}
    }

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
    Write-Log "Continue YAML v1 written -> $configPath"

    $rulesContent = @"
# Local AI Development Rules
- Write clean, modular, modern, and well-typed code.
- Always include error handling and handle edge cases gracefully.
- Follow idioms and conventions of the target programming language.
- Do not leave unfinished placeholder comments like '// TODO' without implementation.
"@
    [System.IO.File]::WriteAllText($rulesPath, $rulesContent, $utf8NoBom)
    Write-Log "Developer rules written -> $rulesPath"
}

# -----------------------------------------------------------------
#  STEP 8  |  Live Health Check, Launch Editor & Summary
# -----------------------------------------------------------------

function Invoke-HealthCheckAndLaunch {
    Write-Step 8 "Health Check & Editor Launch"

    $script:RAG_VERIFIED = $false
    if (Test-OllamaReady) {
        try {
            $body = @{ model = $EMBEDDING_MODEL; prompt = "just one health check" } | ConvertTo-Json -Compress
            $resp = Invoke-WebRequest -Uri "http://127.0.0.1:11434/api/embeddings" -Method Post -Body $body -ContentType "application/json" -UseBasicParsing -TimeoutSec 15
            if ($resp.StatusCode -eq 200) {
                $script:RAG_VERIFIED = $true
                Write-Log "Verified local embeddings (@codebase RAG) with $EMBEDDING_MODEL"
            }
        } catch {
            Write-Warn "Embeddings warmup skipped (will initialize on first @codebase query)"
        }
    }

    if ($script:DETECTED_EDITORS.Count -gt 0) {
        $primary = $script:DETECTED_EDITORS[0]
        try {
            Start-Process $primary.Cmd -ArgumentList "." -WindowStyle Normal
            Write-Log "Launched $($primary.Name) in current directory"
        } catch {
            Write-Info "Open $($primary.Name) manually and click the Continue sidebar icon."
        }
    }
}

function Show-Summary {
    $inner = $script:BOX_INNER
    $border = $script:G_H * $inner
    $title = "  [OK] JUST ONE SETUP COMPLETE"
    $padTitle = " " * [math]::Max(0, $inner - $title.Length)

    Write-Blank
    Write-Host "  $($script:G_TL)$border$($script:G_TR)" -ForegroundColor Green
    Write-Host "  $($script:G_V)" -NoNewline -ForegroundColor Green
    Write-Host "$title$padTitle" -NoNewline -ForegroundColor White
    Write-Host "$($script:G_V)" -ForegroundColor Green
    Write-Host "  $($script:G_BL)$border$($script:G_BR)" -ForegroundColor Green
    Write-Blank

    Write-Host "  Active Models:" -ForegroundColor White
    $fallbackListed = $false
    foreach ($m in $FINAL_MODELS) {
        Write-Host "    + " -NoNewline -ForegroundColor Cyan
        Write-Host "$m" -NoNewline -ForegroundColor Green
        if ($m -eq $FALLBACK_MODEL) {
            $fallbackListed = $true
            Write-Host "  [chat, edit, tab-autocomplete]" -ForegroundColor DarkGray
        } else {
            Write-Host "  [chat, edit]" -ForegroundColor DarkGray
        }
    }
    if (-not $fallbackListed) {
        Write-Host "    + " -NoNewline -ForegroundColor Cyan
        Write-Host "$FALLBACK_MODEL" -NoNewline -ForegroundColor Green
        Write-Host "  [tab-autocomplete]" -ForegroundColor DarkGray
    }
    Write-Host "    + " -NoNewline -ForegroundColor Cyan
    Write-Host "$EMBEDDING_MODEL" -NoNewline -ForegroundColor Green
    Write-Host "  [@codebase RAG]" -ForegroundColor DarkGray

    Write-Blank
    $editorList = if ($script:DETECTED_EDITORS.Count -gt 0) { ($script:DETECTED_EDITORS | ForEach-Object { $_.Name }) -join ", " } else { "None detected" }
    $apiText = if (Test-OllamaReady) { "Online (127.0.0.1:11434)" } else { "Warming up" }
    $ragText = if ($script:RAG_VERIFIED) { "Verified" } else { "On-demand" }

    $topTitle = "$($script:G_H) DEPLOYMENT SUMMARY "
    Write-Host "  $($script:G_TL)$topTitle$($script:G_H * ($inner - $topTitle.Length))$($script:G_TR)" -ForegroundColor DarkCyan
    Write-CardLine -Label "Editors   " -Value $editorList -ValueColor "Cyan"
    Write-CardLine -Label "Config    " -Value "~/.continue/config.yaml" -ValueColor "White"
    if ($script:BACKUP_PATH) {
        Write-CardLine -Label "Backup    " -Value (Split-Path $script:BACKUP_PATH -Leaf) -ValueColor "DarkGray"
    }
    Write-CardLine -Label "Ollama API" -Value $apiText -ValueColor $(if (Test-OllamaReady) { "Green" } else { "Yellow" })
    Write-CardLine -Label "RAG Status" -Value $ragText -ValueColor $(if ($script:RAG_VERIFIED) { "Green" } else { "Gray" })
    Write-Host "  $($script:G_BL)$border$($script:G_BR)" -ForegroundColor DarkCyan

    Write-Blank
    Write-Host "  Quick Shortcuts:" -ForegroundColor White
    Write-Host "    Ctrl+L  Chat with AI      |  Ctrl+I     Inline Code Edit" -ForegroundColor DarkGray
    Write-Host "    Tab     FIM Autocomplete  |  @codebase  Semantic Project Search" -ForegroundColor DarkGray
    Write-Blank

    $credit1 = "  Engineered by Moshiur Rahman Deap"
    $credit2 = "  Web: https://one.moshiur.pro  |  https://moshiur.pro"
    $credit3 = "  Git: https://github.com/moshiurrahmandeap11"
    Write-Host "  $($script:G_TL)$border$($script:G_TR)" -ForegroundColor DarkGray
    Write-Host ("  $($script:G_V)$credit1" + (" " * [math]::Max(0, $inner - $credit1.Length)) + "$($script:G_V)") -ForegroundColor Cyan
    Write-Host ("  $($script:G_V)$credit2" + (" " * [math]::Max(0, $inner - $credit2.Length)) + "$($script:G_V)") -ForegroundColor Gray
    Write-Host ("  $($script:G_V)$credit3" + (" " * [math]::Max(0, $inner - $credit3.Length)) + "$($script:G_V)") -ForegroundColor Gray
    Write-Host "  $($script:G_BL)$border$($script:G_BR)" -ForegroundColor DarkGray
    Write-Blank
}

function Open-GitHub {
    $url = "https://github.com/moshiurrahmandeap11"
    if ([Environment]::UserInteractive -and (-not [Console]::IsInputRedirected) -and ($env:JUST_ONE_AUTO -ne "1")) {
        Write-Host "  Star/visit github.com/moshiurrahmandeap11? [y/N]: " -NoNewline -ForegroundColor DarkGray
        try {
            $openChoice = Read-Host
            if ($openChoice -match '^[yY]') {
                Start-Process $url
            }
        } catch {}
    }
}

# -----------------------------------------------------------------
#  ENTRY POINT
# -----------------------------------------------------------------

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
Show-Banner
if (-not $isAdmin) {
    Write-Info "Running in standard User mode (Admin recommended for first-time Ollama install)."
}

Get-SystemInfo
Setup-Ollama
Setup-Editors
Get-OllamaModels
Show-ModeSelector
Install-AllModels
Set-ContinueConfig
Invoke-HealthCheckAndLaunch
Show-Summary
Open-GitHub

if ([Environment]::UserInteractive -and (-not [Console]::IsInputRedirected) -and ($env:JUST_ONE_AUTO -ne "1")) {
    try {
        Write-Blank
        Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey([System.Management.Automation.Host.ReadKeyOptions]::NoEcho -bor [System.Management.Automation.Host.ReadKeyOptions]::IncludeKeyDown)
    } catch {}
}
