# 编译运行 llama.cpp（Windows 指南）

本指南适用于在 Windows 上编译 [llama.cpp](https://github.com/ggml-org/llama.cpp)，并用小模型（如 GGUF 格式的 Llama-3.2-1B、SmolLM2-360M 等）跑起来。

## 1. 获取 llama.cpp 源码
有两种方式：

### 方式 A：Git（推荐）
如果有 Git：
```bash
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
```

### 方式 B：直接下载 ZIP
从 GitHub 下载 [llama.cpp zip](https://github.com/ggml-org/llama.cpp/archive/refs/heads/master.zip)，解压到当前目录，重命名为 `llama.cpp`。

## 2. 安理、准备编译环境（Windows）
llama.cpp 支持多种后端。对于普通消费级 PC，最常用的是：

| 后端 | 适用硬件 | 推荐度 |
|---|---|---|
| CPU（AVX/AVX2/AVX512） | 所有 x86_64 CPU | 必须，最通用 |
| Vulkan | AMD/NVIDIA/Intel 显卡（支持 Vulkan） | 推荐，跨平台且易用 |
| CUDA | NVIDIA 显卡 | 推荐（性能最好，需安装 CUDA Toolkit) |
| HIP/ROCm | AMD 显卡 | 推荐（Linux 为主，Windows 支持有限） |
| SYCL | Intel 显卡/CPU | 可选 |

Windows 上常用的编译方式有两种：**CMake + Visual Studio（MSVC）** 或 **CMake + MinGW-w64**。

### 环�视准备
- [Visual Studio 2022](https://visualstudio.microsoft.com/)（安装 "Desktop development with C++" 工作负载）- MSVC 最常用
- [CMake](https://cmake.org/download/)（>= 3.14，建议 >= 3.21）
- [Git](https://git-scm.com/download/win)（如用 Git 克隆）
- （可选）[NVIDIA CUDA Toolkit](https://developer.nvidia.com/cuda-downloads)（CUDA 后端）
- （可选）[Vulkan SDK](https://vulkan.lunarg.com/sdk/home)（Vulkan 后端）

## 3. 编译（CMake）

进入源码目录：
```bash
cd llama.cpp
```

### 方式 3a：纯 CPU（最简单，无需额外 SDK）
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j
```

编译产物在 `build\bin\Release\`（MSVC）或 `build\bin\`（MinGW）。

### 方式 3b：Vulkan（推荐，适合大多数独显）
确保已安装 Vulkan SDK 并配置好环境变量（`VULKAN_SDK`）。
```bash
cmake -B build -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j
```

### 方式 3c：CUDA（NVIDIA）
确保已安装 CUDA Toolkit，且 `nvcc` 在 PATH 中。
```bash
cmake -B build -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j
```

> 如果用 MinGW 编译而不是 MSVC，去掉 `--config Release`（按实际生成器调整）。使用 Visual Studio 生成器时才需要 `--config`。

## 4. 获取小模型（GGUF 格式）
llama.cpp 需要 GGUF 格式模型。推荐从 HuggingFace 获取小模型：

常用小模型（适合入门）：
| 模型 | 大小（GGUF） | 说明 |
|---|---|---|
| [SmolLM2-360M-Instruct](https://huggingface.co/HuggingFaceTB/SmolLM2-360M-Instruct-GGUF) | ~250MB | 很小，速度快，适合 CPU 测试 |
| [Llama-3.2-1B-Instruct](https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF) | ~700MB | 较常用，效果更好 |
| [Qwen2.5-0.5B-Instruct](https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF) | ~400MB | 中文支持也不错 |

下载 `.gguf` 文件（如 `smollm2-360m-instruct.Q2_K_M.gguf`）放到 `llama.cpp\models\` 目录。

## 5. 运行（推理）
编译完成后，可用 `llama-cli`（交互式）或 `llama-server`（API 服务）。

### 交互式对话（llama-cli）
进入编译产物目录，或直接用相对路径：

```bash
# MSVC
.\build\bin\Release\llama-cli.exe -m .\models\smollm2-360m-instruct.Q2_K_M.gguf -ngl 99 -c 2048 --temp 0.7 --top-p 0.9 -n 512 -p "你好，请介绍一下你自己。"
```

### 简单交互模式
```bash
.\build\bin\Release\llama-cli.exe -m .\models\smollm2-360m-instruct.Q2_K_M.gguf -ngl 99 -c 2048 --interactive
```

### 启动 API 服务（llama-server）
```bash
.\build\bin\Release\llama-server.exe -m .\models\smollm2-360m-instruct.Q2_K_M.gguf -ngl 99 -c 4096 --host 127.0.0.1 --port 8080
```
然后访问 `http://127.0.0.1:8080` 或用 OpenAI 兼容接口调用。

### 常用参数说明
| 参数 | 说明 |
|---|---|
| `-m, --model` | GGUF 模型文件路径 |
| `-ngl, --n-gpu-layers` | GPU 加速层数，设为 `99` 表示尽可能用 GPU |
| `-c, --context-size` | 上下文长度（根据显存调整） |
| `-t, --threads` | CPU 线程数（默认自动） |
| `-n, --n-predict` | 最大生成 token 数 |
| `-p, --prompt` | 预设提示词 |
| `--interactive` | 交互式对话模式 |
| `--temp` | 温度（随机性） |
| `--top-p, --top-k` | 采样参数 |

## 6. 快速验证清单
- [ ] 源码已获取（Git 克隆或 ZIP 解压）
- [ ] 编译环境准备好（CMake + MSVC/MinGW）
- [ ] 成功编译（生成 `llama-cli.exe`、`llama-server.exe`）
- [ ] 下载 GGUF 小模型并放到 `models/`目录
- [ ] 成功运行 `llama-cli` 生成回答
- [ ] （可期望) API 服务可正常访问

## 7. 常见问题
| 问题 | 解决方案 |
|---|---|
| 编译很慢 | 使用 `-j` 多核编译，或减少并行度避免内存不足 |
| 找不到 Vulkan/CUDA | 检查 SDK 是否安装、环境变量是否正确，重新运行 CMake 配置 |
| 显存不足 | 降低 `-ngl`（用更多 CPU）、降低 `-c`（上下文长度）、换更小的量化（Q2）模型 |
| 运行时找不到 DLL | MSVC 需确保有 Visual C++ Redistributable；Vulkan 需有 `vulkan-1.dll` |
| 对话乱码/输出异常 | 检查终端编码（Windows Terminal 建议使用 UTF-8） |

## 8. 一键脚本思路（可选）
如果需要，可以在 `llama.cpp` 目录下创建 `build_and_run.bat`：
```bat
@echo off
cmake -B build -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j
.\build\bin\Release\llama-cli.exe -m .\models\smollm2-360m-instruct.Q2_K_M.gguf -ngl 99 -c 2048 --interactive
pause
```

---

**提示：** 对于首次编译，推荐先用 **CPU 或 Vulkan** 后端跑通全流程，再尝试 CUDA 等更复杂的配置。用 360M Q2 量化模型是最省资源也最容易成功的入门组合。
