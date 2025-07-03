#!/bin/bash

# 简单的脚本，启动Host Agent
# 需要在一个独立的终端窗口运行

# 设置工作目录
cd "$(dirname "$0")/../demo/ui" || exit

# 激活虚拟环境
source .venv/bin/activate

# 启动Host Agent
echo "Running Host Agent UI..."
uv run main.py

# 如果需要指定端口，可以使用：
# uv run main.py --port 12000 