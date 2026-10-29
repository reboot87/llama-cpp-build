# 自动化编译运行 llama.cpp

## 一键启动（最简单）
双击 `auto_setup_llama.cpp.bat`，脚本会自动完成：

1. **Clone** - 克隆 [llama.cpp](https://github.com/ggml-org/llama.cpp)（如果已存在则跳过）
2. **下载模型** - 自动下载 `SmolLM2-360M-Instruct-GGUF Q2_K_M` 到 `models/` 目录（约 250 MB）
3. **编#(编译)** - 自动尝# 后端（Vulkan > CUDA > CPU），并行编译
4. **验证** - 编译完成后自动运行一次验证推理（输出 20 个 token）以确认可用

## 手动运行 PowerShell 蚠本
如果需要自定义参数，可以直接运行 PowerShell 脚本：

```powershell
cd E:\workspace\smodel
.\auto_setup_llama.cpp.ps1
```

自定义模型 URL：
```powershell
.\auto_setup_llama.cpp.ps1 -ModelUrl "https://huggingface.co/.../model.gguf" -ModelName "model.gguf"
```

## 输出文件
| 文件 | 说明 |
|---read?]
| `llama.cpp/` | 克隆的源码（成功后生成）
| `models/` | 下载的 GGUF 模odel
| `llama.cpp/build/` | 编译产物（`llama-cli.exe`, `llama-server.exe`）
| `auto_setup_debug.log` | 详细日志 (调试用) |

## 验证成功的标志
脚本会输出类似：
```
[HH:mm:ss][OK] 编译成功
[HH:mm:ss][OK] 找到 llama-cli：...\build\bin\Release\llama-cli.exe
[HH:mm:ss][OK] 验证运行：使用小模型进行简单推理...
你好...
[HH:mm:ss][OK] === 自动化流程完成 ===
```

## 常用运行方式（自动化完成后）
```bash
# 交互式对话
.\llama.cpp\build\bin\Release\llama-cli.exe -m .\models\smollm2-360m-instruct.Q2_K_M.gguf -ngl 99 -c 2048 --interactive

# API 服务
# PR
.\llama.cpp\build\bin\Release\llama-server.exe -m .\models\smollm2-360m-instruct.Q2_K_M.gguf -ngl 99 -c 4096 --host 127.0.0.1 --port 8080
```

## 注意事项
- **编译环境**：Windows 上需安装 Visual Studio 2022（"Desktop development with C++"）或 MinGW-w64。如果两者都没有，CMake 可能会配置失败。
- **网络**: 首次需下载源码（~几 MB）和模型（~250 MB）
- **时间**: 编译可能需要 5-15 分钟（视 CPU 而定）
- **显存/内、: SmolLM2-360M Q2 很小，通常 1GB+ 内存即可运行
- **执行策略**：如果 PowerShell 限制了脚本执行，可使用 `powershell -ExecutionPolicy Bypass -File ...`（本脚本的 BAT 已包含）
- **Vulkan/CUDA**：脚本会自动检测并尝试，如果硬件不支持对应后端会自动回退
- **日志**: 如果失败，请先查看 `auto_setup_debug.log` 获取详细错误信息
```
