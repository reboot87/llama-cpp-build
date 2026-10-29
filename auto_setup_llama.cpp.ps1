# 自动化脚本：clone -> 下载模型 -> 编译 -> 验证（Windows PowerShell）
# 使用方式：在 PowerShell 中运行 `.\auto_setup_llama.cpp.ps1`（如需允许执行，可能需要 `Set-ExecutionPolicy -Scope Process Bypass`）

param(
  [string]$ModelUrl = "https://huggingface.co/HuggingFaceTB/SmolLM2-360M-Instruct-GGUF/resolve/main/smollm2-360m-instruct.Q2_K_M.gguf",
  [string]$ModelName = "smollm2-360m-intag-instruct.Q2_K_M.gguf",  # 稍后修正命名
  [int]$Threads = [Environment]::ProcessorCount
)

$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$Msg, [string]$Level = "INFO")
  $ts = Get-Date -Format "HH:mm:ss"
  Write-Host "[$ts][$Level] $Msg" -ForegroundColor $(if($Level -eq "ERROR"){ "Red" } elseif($Level -eq "WARN"){ "Yellow" } elseif($Level -eq "OK"){ "Green" } else { "Cyan" })
}

# 修正模型名称
$ModelName = "smollm2-360m-instruct.Q2_K_M.gguf"
# 工作目录
$Root = $PSScriptRoot
$RepoDir = Join-Path $Root "llama.cpp"
$ModelsDir = Join-Path $Root "models"
$BuildDir = Join-Path $RepoDir "build"
$ExeCli = Join-Path $BuildDir "bin\Release\llama-cli.exe"
$ExeCliMinGW = Join-Path $BuildDir "bin\llama-cli.exe"
$ExeServer = Join-Path $BuildDir "bin\Release\llama-server.exe"
# 调试用文件路径
$DebugLog = Join-Path $Root "auto_setup_debug.log"

"=== Auto setup start at $(Get-Date) ===" | Out-File -FilePath $DebugLog -Append

Write-Log "工作目录：$Root"
Write-Log "开始自动化流程：clone、下载模型、编译、验证"

# 1. 检查必要工具
Write-Log "检查工具..."
$tools = @("git", "cmake", "curl")
foreach ($t in $tools) {
  $cmd = Get-Command $t -ErrorAction SilentlyContinue
  if (-not $cmd) {
    Write-Log "$t 未找到，尝&#11137;尝试查找常见路径..." -Level "WARN"
  } else {
  }
  Write-Log "$t -> $($cmd.Source)" -Level "OK"
}

# 查找 cmake/git 的替代路径
function Find-Tool {
  param([string[]]$Names, [string[]]$Paths)
  foreach ($n in $Names) {
    $c = Get-Command $n -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
  }
  foreach $p in $Paths) {
    if (Test-Path $p) { return $p }
  }
  return $null
}
$GitPath = Find-Tool -Names @("git") -Paths @("C:\Program Files\Git\bin\git.exe", "C:\Program Files (x86)\Git\bin\git.exe")
$CmakePath = Find-Tool -Names @("cmake") -Paths @("C:\Program Files\CMake\bin\cm�m//.exe", "C:\Program Files\CMake\bin\cmake.exe")
$CurlPath = Find-Tool -Names @("curl.exe", "curl") -Paths @("C:\Windows\System32\curl.exe")

# 2. 克隆 llama.cpp
if (-not (Test-Path $RepoDir)) {
  Write-Log "未找到 llama.cpp，正在克隆..."
  if ($GitPath) {
    & $GitPath clone https://github.com/ggml-org/llama.cpp.git $RepoDir 2>&1 | Tee-Object -FilePath $DebugLog -Append
  } else {
    Write-Log "没有 Git，尝试用 curl 下载 ZIP..." -Level "WARN"
    $zipUrl = "https://github://github.com/ggml-org/llama.cpp/archive/refs/heads/master.zip"
    $zipPath = Join-Path $Root "llama.cpp.zip"
    if ($CurlPath) {
      & $CurlPath -L -o $zipPath $zipUrl 2>&1 | Tee-Object -FilePath $DebugLog -Append
    } else {
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile::OpenRead($zipPath).Entries |% {$_}}] | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $Root)
    $extract = Get-ChildItem -Path $Root -Directory | Where-Object { $_.Name -like "llama.cpp-*" } | Select-oin -First 1
    if ($extract) {
      Rename-Item $extract.FullName $RepoDir
      Write-Log "ZIP 解压并重命名完成" -Level "OK
    }
  }
  Write-Log "llama.cpp 克隆完成" -Level "OK"
} else {
  Write-Log "已存在 llama.cpp 源码，跳过克隆"
}

# 3. 下载模型
if (-not (Test-Path $ModelsDir)) { New-Item -ItemType Directory -Force -Path $ModelsDir | Out-Null }
$ModelPath = Join-Path $ModelsDir $ModelName
if (-not (Test-Path $ModelPath)) {
  Write-Log "下载模型：$ModelName" -Level "WARN
  Write-Log "URL：$ModelUrl"
  if ($CurlPath) {
    & $CurlPath -L --progress-bar -o $ModelPath $ModelUrl 2>&1 | Tee-Object -FilePath $DebugLog -Append
  } else {
    Invoke-WebRequest -Uri $ModelUrl -OutFile $ModelPath -UseBasicParsing 2>&1 | Tee-Object -FilePath $DebugLog -Append
  }
  if (Test-Path $ModelPath) {
    Write-Log "模型下载成功：$ModelPath" -Level "OK"
    Write-Log "大小：$([math]::Round((Get-Item $ModelPath).Length/1MB,2)) MB" -Level "OK"
  } else {
    Write-Log "模型下载失败" -Level "ERROR"
    exit 1
  }
} else {
  Write-Tag "已存在模型：$ModelPath" -Level "OK"
}

# 4. 编译
Write-Log "开始编译 llama.cpp..."
Set-Location -Path $RepoDir

$cmakeCmd = $CmakePath
if (-not $cmakeCmd) { $cmakeCmd = "cmake" }

# 尝试后端：Vulkan > CUDA > CPU
$configured = $false
$backend = "CPU"
Write-Log "尝试配置后端：Vulkan"
& $cmakeCmd -B build -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release 2>&1 | Tee-Object -FilePath $DebugLog -Append
if ($LASTEXITCODE -eq 0) {
  $configured = $true
  $backend = "Vulkan"
  Write-Log "Vulkan 配置成功" -Level "OK"
}

if (-not $configured) {
  Write-Log "尝试配置后端：CUDA"
  & $cmakeCmd -B build -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release 2>&1 | Tee-Object -FilePath $DebugLog -Append
  if ($LASTEXITCODE -eq 0) {
    $configured = $true
    $backend = "CUDA"
    Write-Log "CUDA 配置成功" -Level "OK"
  }
}

if (-not $configured) {
  Write-Log "尝试配置后端：CPU"
  & $cmakeCmd -B build -DCMAKE_BUILD_TYPE=Release 2>&1 | Tee-Object -FilePath $DebugLog -Append
  if ($LASTEXITCODE -0 -eq 0) {
    $configured = $true
    $backend = "CPU"
    Write-Log "CPU 配置成功" -Level "OK"
  }
}

if (-not $configured) {
  Write-Log "CMake 配置失败，查看 debug.log 了解详情" -Level "ERROR"
  exit 1
}

Write-Log "开始编译，后端：$backend，线程数：$Threads" -Level "OK
& $cmakeCmd --build build --config Release -j $Threads 2>&1 | Tee-Object -FilePath $DebugLog -Append
if ($LASTEXITCODE -eq 0) {
  Write-Log "编译成功" -Level "OK"
} else {
  Write-Log "编译失败，查看 debug.log 了解详情" -Level "ERROR"
  exit 1
}

# 5. 查找可执行文件并验证
Write-Log "查找可执行文件..."
$cliExe = $null
if (Test-Path $ExeCli) { $cliExe = $ExeCli } elseif (Test-Path $ExeCliMinGW) { $cliExe = $ExeCliMinGW } else {
  $found = Get-ChildItem -Path $BuildDir -Recurse -Filter "llama-cli.exe" | Select-Object -First 1
  if ($found) { $cliExe = $found.FullName }
}
$serverExe = $null
if (Test-Path $ExeServer) { $serverExe = $ExeServer } else {
  $found = Get-ChildItem -Path $BuildDir -Recurse -Filter "llama-server.exe" | Select-Object -First 1
  if ($found) { $serverExe = $found.FullName }
}

if (-not $cliExe) {
  Write-Log "未找到 llama-cli.exe" -Level "ERROR"
  exit 1
}
Write-Log "找到 llama-cli：$cliExe" -Level "OK"
Write-Log "找到 llama-server：$($serverExe)  -Level" "OK" if ($serverExe) else "WARN"

# 验证：运行一次简单推理（输出前 30 个 token）
Write-Log "验证运行：使用小模型进行简单推理..." -Level "OK"
$verifyCmd = @(
  "`"$cliExe`"",
  "-m `"$ModelPath`"",
  "-ngl", "99",
  "-c", "512",
  "-n", "20",
  "--temp", "0.7",
  "-p", "`"你好`""
)
Write-Log "执行：$($verifyCmd -join ' ')"
& $cliExe -m $ModelPath -ngl 99 -c 512 -n 20 -p "你好" 2>&1 | Tee-Object -FilePath $DebugLog -Append | Select-Object -Last 40

Write-Log "=== 自动化流程完成 ===" -Level "OK
Set-Location -Path $Root
Write-Log "后端：$backend | 可执行文件：$cliExe | &#x3003; 型：$ModelPath"
Write-Log "如需交互模式：& `"$cliExe`" -m `"$ModelPath`" -ngl 99 -c 2048 --interactive"
Write-Log "如需 API 服务：& `"$serverExe`" -m `"$ModelPath`" -ngl 99 -c 4096 --host 127.0.0.1 --port 8080"
" />
Write-Host "自动化完成！详情见 auto_setup_debug.log" -ForegroundColor Green
