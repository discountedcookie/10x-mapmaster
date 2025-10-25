#!/bin/bash
# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | xargs)
fi

# Execute the actual MCP server command passed as arguments
exec "$@"