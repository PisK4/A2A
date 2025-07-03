#!/bin/bash

# 简单的脚本，启动Food Ordering Service Agent
# 需要在一个独立的终端窗口运行

# 设置工作目录
cd "$(dirname "$0")/../samples/python" || exit

# 激活虚拟环境
source .venv/bin/activate

# 设置必要的环境变量
export APTOS_NODE_URL="https://api.devnet.aptoslabs.com/v1"
export APTOS_PRIVATE_KEY="ed25519-priv-0x280170ba1051145feaadec53769c92005c4b094cd260d339529be424a30b97b4"
export HOST_AGENT_APTOS_ADDRESS="0x42e86d92f3d8645d290844f96451038efc722940fff706823dd3c0f8f67b46bd"
export APTOS_MODULE_ADDRESS="0x42e86d92f3d8645d290844f96451038efc722940fff706823dd3c0f8f67b46bd"

# 自动获取Aptos测试币
echo "检查并获取Aptos Devnet测试币..."
python ../../scripts/get_aptos_faucet.py "$APTOS_PRIVATE_KEY"
if [ $? -ne 0 ]; then
    echo "⚠️ 获取测试币失败，但继续启动Food Agent"
fi

# 启动Food Ordering Service Agent
echo "Running Food Ordering Service Agent..."
uv run agents/food_ordering_services --host 0.0.0.0 --port 10003

# 如果需要指定端口，可以使用：
# uv run agents/food_ordering_services --port 10002 