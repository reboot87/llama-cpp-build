@echo off
REM 快速编译运行 llama.cpp（Windows）
REM 请先下载 GGUF 模型到 models\ 目录，例如 smollm2-360m-instruct.Q2_K_M.gguf

setlocal

REM 检查源码
if not exist "llama.cpp\CMakeLists.txt" (
    echo [ERROR] 未找到 llama.cpp 源码
    echo 请先克隆或解压：git clone https://github.com/ggml-org/llama.cpp.git
    pause
    exit /b 1
)

cd llama.cpp

REM 检查模型
if not exist "..\models\smollm2-360m-instruct.Q2_K_M.gguf" (
    if not exist "models\smollm2-360m-instruct.Q2_K_M.gguf" (
        echo [WARN] 未检测到默认模型 smollm2-360m-instruct.Q2_K_M.gguf
        echo 请下载 GGUF 模型到以下任意位置：
        echo   - %CD%\models\
        echo   - %CD%\..\models\
        echo 然后修改本脚本中的 MODEL 路径
        echo.
    )
)

REM 编译（默认尝试 Vulkan，失败则回退 CPU）
echo [INFO] 正在配置 CMake...
cmake -B build -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] Vulkan 配置失败，改用纯 CPU 编译...
    cmake -B build -DCMAKE_BUILD_TYPE=Release
)

echo [INFO] 正在编译（可能需要数分钟）...
cmake --build build --config Release -j %NUMBER_OF_PROCESSORS%

echo [INFO] 编译完成！
echo [INFO] 准备运行模型...

REM 查找模型路径
set MODEL=..\models\smollm2-360m-instruct.Q2_K_M.gguf
if exist "models\smollm2-360m-instruct.Q2_K_M.gguf" set MODEL=models\smollm2-360m-instruct.Q2_K_M.gguf

if not exist "%MODEL%" (
    echo [ERROR] 找不到模型文件
    echo 请编辑脚本设置正确的 MODEL 路径
    pause
    exit /b 1
)

REM 运行
.\build\bin\Release\llama-cli.exe -m "%MODEL%" -ngl 99 -c 2048 --interactive

pause
endlocal
