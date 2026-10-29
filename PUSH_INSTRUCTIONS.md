# 推送到 GitHub 并触发编译

仓库：`https://github.com/reboot87/llama-cpp-build.git`

## 方法 1：网页上传（最简单）
1. 打开 https://github.com/reboot87/llama-cpp-build
2. 点击 "Add file" → "Upload files"
3. 将本目录下的 `.github/workflows/build-llama.yml` 上传到仓库（保持目录结构：`.github/workflows/build-llama.yml`）
4. 提交 Commit
5. 上传完成后，进入仓库的 "Actions" tab，选择 "Build llama.cpp Windows MSVC" 工作流，点击 "Run workflow" 手动触发（或直接推送到 main 会触发）

## 方法 2：Git 客户端上传
复制 `.github/workflows/build-llama.yml` 到仓库本地克隆的相同路径下，然后 `git add / commit / push`。

## 编译产物获取
一次触发会并行构建两个配置（Release 与 Debug），约 30-60 分钟（视队列而定）。完成后在 "Actions" > 工作流运行 > 页面底部的 "Artifacts" 中下载：

| Artifact | 说明 |
| --- | --- |
| `llama-cpp-windows-msvc-x64-Release` | 发布版，体积小、速度快 |
| `llama-cpp-windows-msvc-x64-Debug` | 调试版，带 `.pdb` 符号，可挂调试器；附带 Debug CRT 运行库 |

解压后即可在本地 Windows 直接运行 `llama-cli.exe`、`llama-server.exe`，无需安装 Visual Studio。

## 工作流说明
- 从 `ggml-org/llama.cpp` 主分支检出源码，使用 `windows-2022`（MSVC v143 / VS2022）构建。
- 纯 CPU 版本，`GGML_NATIVE=OFF` + 显式 AVX/AVX2/FMA/F16C，避免产物绑死 CI 机器的指令集（runner 可能支持 AVX512，那样产出的 exe 在普通机器上会非法指令崩溃）。
- `BUILD_SHARED_LIBS=ON`，产出 `llama.dll`、`ggml.dll`、`ggml-base.dll`、`ggml-cpu.dll` 等运行时插件 DLL。
- 收集阶段会把 `build\bin\<Config>\` 下的 exe/dll/pdb 全部打包，并额外带上 VC 运行库：
  - Release：`Microsoft.VC143.CRT`（vcruntime140 / msvcp140）
  - Debug：额外带 `debug_nonredist\x64\Microsoft.VC143.DebugCRT`（`*d.dll`），否则目标机没装 VS 会直接报缺 DLL / 0xc000007b
- llama.cpp 默认 `LLAMA_OPENSSL=ON`（`-hf` 走 HTTPS 下载模型需要），所以产物还会依赖 `libssl-3-x64.dll`、`libcrypto-3-x64.dll`，这两个会在校验阶段自动从 OpenSSL 安装目录补齐并一起打包。
- 上传前有一道 **依赖闭环校验**：用 `dumpbin /dependents` 逐个检查产物里每个 exe/dll 的依赖，缺的 DLL 先自动补齐；补不到才让 job 失败并列出「哪个 DLL 被谁需要」，保证不会上传残缺的包。
