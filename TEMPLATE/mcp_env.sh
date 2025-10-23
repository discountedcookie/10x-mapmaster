#!/bin/bash

# MCP Environment Setup Script
# This script sets up the environment for MCP servers

# Load environment variables if .env.local exists
if [ -f ".env.local" ]; then
    set -a
    source .env.local
    set +a
fi

# Execute the command passed as arguments
exec "$@"
