#!/bin/bash

# Project Setup Script for {{PROJECT_NAME}}
# This script helps set up a new project from the template

set -e

PROJECT_NAME="{{PROJECT_NAME}}"
TEMPLATE_DIR="$(dirname "$0")/.."

echo "🚀 Setting up project: $PROJECT_NAME"

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the project root."
    exit 1
fi

# Replace template variables
echo "📝 Replacing template variables..."
find . -type f \( -name "*.json" -o -name "*.yml" -o -name "*.toml" -o -name "*.ts" -o -name "*.js" -o -name "*.md" \) -exec sed -i.bak "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" {} \;
find . -name "*.bak" -delete

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Setup environment
echo "🔧 Setting up environment..."
if [ ! -f ".env.local" ]; then
    cp env.example .env.local
    echo "📝 Created .env.local from template"
    echo "⚠️  Please edit .env.local with your actual values"
fi

# Initialize Supabase
echo "🗄️  Initializing Supabase..."
if command -v supabase &> /dev/null; then
    supabase start
    echo "✅ Supabase started successfully"
else
    echo "⚠️  Supabase CLI not found. Please install it first:"
    echo "   npm install -g supabase"
fi

# Generate types
echo "🔧 Generating TypeScript types..."
npm run supabase:types

echo "✅ Project setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env.local with your actual values"
echo "2. Start development: npm run dev"
echo "3. Open Supabase Studio: http://localhost:54323"
echo "4. Start building your app!"
