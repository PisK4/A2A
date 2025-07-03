#!/bin/bash

# 简单的脚本，启动Host Agent
# 需要在一个独立的终端窗口运行

# 设置工作目录
cd "$(dirname "$0")/../demo/ui" || exit

# 激活虚拟环境
source .venv/bin/activate

# 设置必要的环境变量
export APTOS_NODE_URL="https://api.devnet.aptoslabs.com/v1"
export APTOS_PRIVATE_KEY="ed25519-priv-0x527ff01b4f55ecd7c6c96eb711be968f8dd42125984b751ddd856c7b5bdcbeac"
export APTOS_MODULE_ADDRESS="0x42e86d92f3d8645d290844f96451038efc722940fff706823dd3c0f8f67b46bd"
export DEFAULT_REMOTE_AGENTS="http://localhost:10003"

# 自动获取Aptos测试币
echo "检查并获取Aptos Devnet测试币..."
python ../../scripts/get_aptos_faucet.py "$APTOS_PRIVATE_KEY"
if [ $? -ne 0 ]; then
    echo "⚠️ 获取测试币失败，但继续启动Host Agent"
fi

# 启动Host Agent
echo "Running Host Agent UI..."
uv run main.py

# 如果需要指定端口，可以使用：
# uv run main.py --port 12000 