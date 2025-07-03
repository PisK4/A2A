#!/bin/bash

# Start Custom Agent script
# This script starts the Custom Agent with A2A protocol support and signature verification

# Set working directory to the project root
cd "$(dirname "$0")/.." || exit

# Variables
PORT=${1:-10002}
AGENT_DIR="samples/python/agents/google_adk"
ENV_FILE="$AGENT_DIR/.env"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Custom Agent with signature verification...${NC}"

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

# Check for ETH_PRIVATE_KEY
if [ -n "$ETH_PRIVATE_KEY" ]; then
    export ETH_PRIVATE_KEY="$ETH_PRIVATE_KEY"
    echo -e "${GREEN}ETH_PRIVATE_KEY is available for signature verification${NC}"
    echo -e "${GREEN}Key begins with: ${ETH_PRIVATE_KEY:0:10}...${NC}"
else
    echo -e "${YELLOW}Warning: ETH_PRIVATE_KEY environment variable not set.${NC}"
    echo -e "${YELLOW}The agent will run but won't be able to validate signatures properly.${NC}"
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
cd "$AGENT_DIR" || exit

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

# Start the agent using uv
echo -e "${GREEN}Starting Custom Agent on port $PORT...${NC}"
echo -e "${GREEN}Running in UV virtual environment${NC}"
uv run . --port "$PORT" --verify-signatures

# Exit with the status of the last command
exit $? 