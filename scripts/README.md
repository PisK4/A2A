# A2A Protocol Scripts

This directory contains scripts for running the A2A (Agent-to-Agent) protocol system with Ethereum signature verification.

## Available Scripts

- `generate_eth_key.py` - Generate a new Ethereum private key for signing messages
- `start_a2a_system.sh` - Start both the Host Agent and Custom Agent together
- `start_custom_agent.sh` - Start only the Custom Agent
- `start_host_agent.sh` - Start only the Host Agent

## Prerequisites

- Python 3.12 or higher
- UV package manager
- Required Python libraries: web3, eth_account, google-adk, google-genai

## Usage

### Generate an Ethereum Key

```bash
python3 scripts/generate_eth_key.py
```

### Start the Complete System

```bash
# Set the Ethereum private key
export ETH_PRIVATE_KEY='0x...'

# Make scripts executable 
chmod +x scripts/*.sh

# Start both agents
./scripts/start_a2a_system.sh
```

### Start Custom Agent Only

```bash
./scripts/start_custom_agent.sh [port]
```

### Start Host Agent Only

```bash
export ETH_PRIVATE_KEY='0x...'
./scripts/start_host_agent.sh [port] [custom-agent-url]
```

## Configuration

- All scripts read from the necessary environment variables
- Default ports: 10002 (Custom Agent) and 12000 (Host Agent)
- See the complete documentation in `docs/improve/implement_signature_verify.md`

# 启动脚本说明

这里提供了两个简单的启动脚本，用于分别在两个终端窗口中启动 Custom Agent 和 Host Agent。

## 脚本说明

- `run_custom_agent.sh` - 在一个终端窗口中启动 Custom Agent
- `run_host_agent.sh` - 在另一个终端窗口中启动 Host Agent UI

## 使用方法

### 启动 Custom Agent

```bash
# 确保脚本有执行权限
chmod +x scripts/run_custom_agent.sh

# 在一个终端窗口中运行
./scripts/run_custom_agent.sh
```

### 启动 Host Agent UI

```bash
# 确保脚本有执行权限
chmod +x scripts/run_host_agent.sh

# 在另一个终端窗口中运行
./scripts/run_host_agent.sh
```

## 注意事项

1. 确保已设置相关环境变量
   ```bash
   # 设置以太坊私钥（用于签名验证）
   export ETH_PRIVATE_KEY="your_key_here"
   
   # 设置Google API密钥（用于LLM访问）
   export GOOGLE_API_KEY="your_api_key_here"
   ```

2. 如果需要更改默认端口，请修改脚本中相应的命令行参数 