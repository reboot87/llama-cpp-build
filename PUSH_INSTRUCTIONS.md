# 推送到 GitHub 并触发编译

由于本环境未检测到可用的 Git/gh CLI，需要手动上传工作流文件到仓库 `https://github.com/reboot87/llama-cpp-build.git`。

## 方法 1：网页上传（最简单）
1. 打开 https://github.com/reboot87/llama-cpp-build
2. 点击 "Add file" → "Upload files"
3. 将本目录下的 `.github/workflows/build-llama.yml` 上传到仓库（保持目录结构：`.github/workflows/build-llama.yml`）
4. 提交 Commit
5. 上传完成后，进入仓库的 "Actions" tab，选择 "Build llama.cpp Windows MSVC" 工作流，点击 "Run workflow" 手动触发（或直接推送到 main 会触发）

## 方法 2：Git 客户端上传
使用本地已有的 Git 客# PR PS 等工具，复制以下文件到仓库本地克隆中并推送：
- `E:\workspace\smodel\.github\workflows\build-llama.yml`

## 编译产物获取
触发后，GitHub Actions 将在约 20-40 分分钟内完成编译（视队列而定）。完成后在 "Actions" > 工作流运行 > "Artifacts" 中下载 `llama-cpp-windows-msvc-x64.zip`，解压后即可在本地 Windows (无需 VS2017 编译环境) 使用 `llama-cli.exe`、`llama-server.exe`。

## 工作流说明
工作流会直接从 `ggml-org/llama.cpp` 主分支检出源码，使用 `windows-2022`（MSVC v143）编��、构建纯 CPU（AVX2）版本，收集所有 `.exe` 和 `.dll` 并打包上传。
```
