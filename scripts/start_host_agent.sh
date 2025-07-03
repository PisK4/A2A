#!/bin/bash

# Start Host Agent script
# This script starts the Host Agent with Ethereum signing capabilities

# Set working directory to the project root
cd "$(dirname "$0")/.." || exit

# Variables
PORT=${1:-12000}
HOST_DIR="demo/ui"
AGENT_ADDRESS=${2:-"http://localhost:10002"}
ENV_FILE="$HOST_DIR/.env"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Host Agent with Ethereum signing capabilities...${NC}"

# Load environment variables from .env file
if [ -f "$ENV_FILE" ]; then
    echo -e "${GREEN}Loading environment variables from $ENV_FILE${NC}"
    # Read each line and export as environment variable
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        if [[ $line =~ ^[^#].+=.+ ]]; then
            key=$(echo "$line" | cut -d '=' -f 1)
            value=$(echo "$line" | cut -d '=' -f 2-)
            # Remove quotes if present
            value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            export "$key=$value"
        fi
    done < "$ENV_FILE"
else
    echo -e "${YELLOW}No .env file found at $ENV_FILE${NC}"
fi

# Check for ETH_PRIVATE_KEY - required for Host Agent
if [ -n "$ETH_PRIVATE_KEY" ]; then
    export ETH_PRIVATE_KEY="$ETH_PRIVATE_KEY"
    echo -e "${GREEN}ETH_PRIVATE_KEY is available for message signing${NC}"
    echo -e "${GREEN}Key begins with: ${ETH_PRIVATE_KEY:0:10}...${NC}"
else
    echo -e "${RED}Error: ETH_PRIVATE_KEY environment variable is required for the Host Agent to sign messages.${NC}"
    echo -e "Please set the environment variable with a valid Ethereum private key:"
    echo -e "export ETH_PRIVATE_KEY=your_private_key_here"
    echo -e "Or add it to $ENV_FILE"
    
    # Prompt to generate a key
    read -p "Would you like to generate a new key now? (y/n): " GENERATE_KEY
    if [[ $GENERATE_KEY == "y" || $GENERATE_KEY == "Y" ]]; then
        echo "Generating new Ethereum key..."
        # Install web3 if needed
        python3 -m pip install web3
        KEY_OUTPUT=$(python3 "scripts/generate_eth_key.py")
        echo "$KEY_OUTPUT"
        echo ""
        # Extract private key from output
        EXTRACTED_KEY=$(echo "$KEY_OUTPUT" | grep "export ETH_PRIVATE_KEY=" | sed "s/export ETH_PRIVATE_KEY='\(.*\)'/\1/")
        if [ -n "$EXTRACTED_KEY" ]; then
            export ETH_PRIVATE_KEY="$EXTRACTED_KEY"
            echo -e "${GREEN}Key generated and set for this session.${NC}"
            
            # Save to .env file
            if [ ! -f "$ENV_FILE" ]; then
                mkdir -p "$(dirname "$ENV_FILE")"
                touch "$ENV_FILE"
            fi
            
            # Check if key already exists in file
            if grep -q "ETH_PRIVATE_KEY=" "$ENV_FILE"; then
                # Update existing key
                sed -i.bak "s/ETH_PRIVATE_KEY=.*/ETH_PRIVATE_KEY=$EXTRACTED_KEY/" "$ENV_FILE"
                rm -f "${ENV_FILE}.bak"
            else
                # Add new key
                echo "ETH_PRIVATE_KEY=$EXTRACTED_KEY" >> "$ENV_FILE"
            fi
            echo -e "${GREEN}Key saved to $ENV_FILE${NC}"
        else
            echo -e "${RED}Failed to extract and set the key automatically.${NC}"
            exit 1
        fi
    else
        exit 1
    fi
fi

# Check for API key
if [ -n "$GOOGLE_API_KEY" ]; then
    export GOOGLE_API_KEY="$GOOGLE_API_KEY"
    echo -e "${GREEN}GOOGLE_API_KEY is available for LLM access${NC}"
elif [ "$GOOGLE_GENAI_USE_VERTEXAI" = "TRUE" ]; then
    export GOOGLE_GENAI_USE_VERTEXAI="TRUE"
    echo -e "${GREEN}Using Vertex AI for LLM access${NC}"
else
    echo -e "${YELLOW}Warning: Neither GOOGLE_API_KEY nor GOOGLE_GENAI_USE_VERTEXAI is set.${NC}"
    echo -e "${YELLOW}The agent will fail to start without proper authentication.${NC}"
    
    # Prompt to set Google API Key
    read -p "Would you like to set a Google API Key now? (y/n): " SET_API_KEY
    if [[ $SET_API_KEY == "y" || $SET_API_KEY == "Y" ]]; then
        read -p "Enter your Google API Key: " INPUT_API_KEY
        if [ -n "$INPUT_API_KEY" ]; then
            export GOOGLE_API_KEY="$INPUT_API_KEY"
            echo -e "${GREEN}API Key set for this session${NC}"
            
            # Save to .env file
            if [ ! -f "$ENV_FILE" ]; then
                mkdir -p "$(dirname "$ENV_FILE")"
                touch "$ENV_FILE"
            fi
            
            # Check if key already exists in file
            if grep -q "GOOGLE_API_KEY=" "$ENV_FILE"; then
                # Update existing key
                sed -i.bak "s/GOOGLE_API_KEY=.*/GOOGLE_API_KEY=$INPUT_API_KEY/" "$ENV_FILE"
                rm -f "${ENV_FILE}.bak"
            else
                # Add new key
                echo "GOOGLE_API_KEY=$INPUT_API_KEY" >> "$ENV_FILE"
            fi
            echo -e "${GREEN}API Key saved to $ENV_FILE${NC}"
        fi
    fi
fi

# Install required packages
echo "Installing dependencies..."
cd "$HOST_DIR" || exit

# Ensure we're using uv and install dependencies
which uv >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}UV not found in PATH. Installing UV...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

echo -e "${GREEN}Using UV for Python environment management${NC}"
uv --version

# Install dependencies
uv pip install -e .
uv pip install web3

# Start the host agent using uv
echo -e "${GREEN}Starting Host Agent UI on port $PORT...${NC}"
echo -e "${GREEN}Will connect to Custom Agent at: $AGENT_ADDRESS${NC}"
echo -e "${GREEN}Running in UV virtual environment${NC}"
uv run main.py

# Exit with the status of the last command
exit $? 