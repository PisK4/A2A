#!/bin/bash

# Master script to start the entire A2A system with signature verification
# This script will start both the Custom Agent and Host Agent

# Set working directory to the project root
cd "$(dirname "$0")/.." || exit

# Variables
CUSTOM_AGENT_PORT=${1:-10002}
HOST_AGENT_PORT=${2:-12000}
SCRIPT_DIR="scripts"
HOST_ENV_FILE="demo/ui/.env"
CUSTOM_AGENT_ENV_FILE="samples/python/agents/google_adk/.env"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}     Starting A2A System with Signature Verification     ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Load environment variables from .env files
echo -e "${YELLOW}Checking for environment files...${NC}"

# Function to read key-value pairs from .env file
read_env_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}Loading environment from: $1${NC}"
        # Read each line and export as environment variable
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip comments and empty lines
            if [[ $line =~ ^[^#].+=.+ ]]; then
                key=$(echo "$line" | cut -d '=' -f 1)
                value=$(echo "$line" | cut -d '=' -f 2-)
                # Remove quotes if present
                value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
                export "$key=$value"
                # If it's ETH_PRIVATE_KEY, mark as found
                if [ "$key" = "ETH_PRIVATE_KEY" ]; then
                    eth_key_found=true
                    echo -e "${GREEN}Found ETH_PRIVATE_KEY in $1${NC}"
                fi
            fi
        done < "$1"
    else
        echo -e "${YELLOW}Environment file not found: $1${NC}"
    fi
}

# Read both environment files
eth_key_found=false
read_env_file "$HOST_ENV_FILE"
read_env_file "$CUSTOM_AGENT_ENV_FILE"

# Check if ETH_PRIVATE_KEY is already set in environment (highest priority)
if [ -n "$ETH_PRIVATE_KEY" ]; then
    eth_key_found=true
    echo -e "${GREEN}Using ETH_PRIVATE_KEY from environment: ${ETH_PRIVATE_KEY:0:10}...${NC}"
fi

# If ETH_PRIVATE_KEY not found anywhere, offer to generate it
if [ "$eth_key_found" = false ]; then
    echo -e "${RED}Error: ETH_PRIVATE_KEY not found in environment or .env files.${NC}"
    echo -e "Please set the environment variable with a valid Ethereum private key:"
    echo -e "export ETH_PRIVATE_KEY=your_private_key_here"
    echo -e "Or add it to ${HOST_ENV_FILE} or ${CUSTOM_AGENT_ENV_FILE}"
    
    # Offer to generate a key
    read -p "Would you like to generate a new key now? (y/n): " GENERATE_KEY
    if [[ $GENERATE_KEY == "y" || $GENERATE_KEY == "Y" ]]; then
        echo "Generating new Ethereum key..."
        # Install web3 if needed
        python3 -m pip install web3
        KEY_OUTPUT=$(python3 "$SCRIPT_DIR/generate_eth_key.py")
        echo "$KEY_OUTPUT"
        echo ""
        # Extract private key from output
        EXTRACTED_KEY=$(echo "$KEY_OUTPUT" | grep "export ETH_PRIVATE_KEY=" | sed "s/export ETH_PRIVATE_KEY='\(.*\)'/\1/")
        if [ -n "$EXTRACTED_KEY" ]; then
            export ETH_PRIVATE_KEY="$EXTRACTED_KEY"
            echo -e "${GREEN}Key generated and set for this session.${NC}"
            echo -e "${YELLOW}Adding key to ${HOST_ENV_FILE}...${NC}"
            
            # Create directory if it doesn't exist
            mkdir -p "$(dirname "$HOST_ENV_FILE")"
            
            # Add key to Host Agent .env file
            echo "ETH_PRIVATE_KEY=$EXTRACTED_KEY" >> "$HOST_ENV_FILE"
            echo -e "${GREEN}Key added to ${HOST_ENV_FILE}${NC}"
            
            # Also add to Custom Agent .env file
            mkdir -p "$(dirname "$CUSTOM_AGENT_ENV_FILE")"
            echo "ETH_PRIVATE_KEY=$EXTRACTED_KEY" >> "$CUSTOM_AGENT_ENV_FILE"
            echo -e "${GREEN}Key added to ${CUSTOM_AGENT_ENV_FILE}${NC}"
        else
            echo -e "${RED}Failed to extract and set the key automatically.${NC}"
            exit 1
        fi
    else
        exit 1
    fi
fi

# Make sure the scripts are executable
chmod +x "$SCRIPT_DIR/start_custom_agent.sh"
chmod +x "$SCRIPT_DIR/start_host_agent.sh"

# Start Custom Agent in background
echo -e "${GREEN}Starting Custom Agent on port $CUSTOM_AGENT_PORT...${NC}"
"$SCRIPT_DIR/start_custom_agent.sh" "$CUSTOM_AGENT_PORT" &
CUSTOM_AGENT_PID=$!

# Wait a bit for the Custom Agent to initialize
echo -e "${YELLOW}Waiting for Custom Agent to initialize...${NC}"
sleep 5

# Start Host Agent
echo -e "${GREEN}Starting Host Agent on port $HOST_AGENT_PORT...${NC}"
"$SCRIPT_DIR/start_host_agent.sh" "$HOST_AGENT_PORT" "http://localhost:$CUSTOM_AGENT_PORT"

# Capture the exit code of the Host Agent
HOST_EXIT_CODE=$?

# If Host Agent exits, kill the Custom Agent
if [ -n "$CUSTOM_AGENT_PID" ]; then
    echo -e "${YELLOW}Shutting down Custom Agent (PID: $CUSTOM_AGENT_PID)...${NC}"
    kill "$CUSTOM_AGENT_PID" 2>/dev/null || true
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}          A2A System shutdown complete                 ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Exit with the Host Agent's exit code
exit $HOST_EXIT_CODE 