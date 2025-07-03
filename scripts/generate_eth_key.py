#!/usr/bin/env python3
"""
Ethereum Private Key Generator for A2A Protocol

This script generates a new Ethereum private key and corresponding address
that can be used for signing messages in the A2A protocol.

Usage:
  python3 generate_eth_key.py

Requirements:
  - web3 library: pip install web3
"""

import os
from eth_account import Account
import secrets


def generate_eth_key():
    """Generate a new Ethereum private key and address."""
    # Generate a random private key
    private_key = "0x" + secrets.token_hex(32)
    
    # Generate the account from the private key
    account = Account.from_key(private_key)
    
    return {
        "private_key": private_key,
        "address": account.address
    }


if __name__ == "__main__":
    try:
        print("Generating new Ethereum key pair for A2A protocol...")
        keys = generate_eth_key()
        
        print("\n" + "=" * 60)
        print("ETHEREUM KEY GENERATED SUCCESSFULLY")
        print("=" * 60)
        print(f"\nAddress:     {keys['address']}")
        print(f"Private Key: {keys['private_key']}")
        print("\n" + "=" * 60)
        print("IMPORTANT: Keep your private key secure and never share it!")
        print("=" * 60)
        
        print("\nTo use this key in the A2A system, set the following environment variable:")
        print(f"\nexport ETH_PRIVATE_KEY='{keys['private_key']}'")
        
    except Exception as e:
        print(f"Error generating Ethereum key: {e}")
        print("Make sure you have installed the web3 library: pip install web3")
        exit(1) 