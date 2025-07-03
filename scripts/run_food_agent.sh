#!/bin/bash

# 简单的脚本，启动Custom Agent
# 需要在一个独立的终端窗口运行

# 设置工作目录
cd "$(dirname "$0")/../samples/python" || exit

# 激活虚拟环境
source .venv/bin/activate

# 启动Custom Agent
echo "Running Food Ordering Service Agent..."
uv run agents/food_ordering_services --host 0.0.0.0 --port 10003

# 如果需要指定端口，可以使用：
# uv run agents/food_ordering_services --port 10002 