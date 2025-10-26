#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏥 Violet Rails EHR - Local Setup${NC}"
echo "===================================="
echo ""

# Step 1: Check Ruby version
echo -e "${BLUE}Step 1: Checking Ruby version...${NC}"
CURRENT_RUBY=$(ruby -v | awk '{print $2}' | cut -d'p' -f1)
REQUIRED_RUBY="2.6.6"

echo "Current Ruby: $CURRENT_RUBY"
echo "Required Ruby: $REQUIRED_RUBY"

if [ "$CURRENT_RUBY" != "$REQUIRED_RUBY" ]; then
    echo -e "${YELLOW}⚠️  Ruby version mismatch${NC}"
    echo ""
    echo "Options:"
    echo "1. Install Ruby 2.6.6 (recommended for compatibility)"
    echo "2. Try with current Ruby 3.4.7 (may work, not tested)"
    echo ""
    read -p "Choose option (1 or 2): " ruby_option
    
    if [ "$ruby_option" = "1" ]; then
        echo ""
        echo -e "${BLUE}Installing Ruby 2.6.6...${NC}"
        
        # Check for rbenv
        if command -v rbenv &> /dev/null; then
            echo "Using rbenv..."
            rbenv install 2.6.6 --skip-existing
            rbenv local 2.6.6
            echo -e "${GREEN}✓ Ruby 2.6.6 installed and set${NC}"
        # Check for rvm
        elif command -v rvm &> /dev/null; then
            echo "Using rvm..."
            rvm install 2.6.6
            rvm use 2.6.6
            echo -e "${GREEN}✓ Ruby 2.6.6 installed and set${NC}"
        else
            echo -e "${RED}✗ Neither rbenv nor rvm found${NC}"
            echo "Install rbenv: brew install rbenv ruby-build"
            echo "Then run this script again"
            exit 1
        fi
        
        # Reload Ruby
        hash -r
        CURRENT_RUBY=$(ruby -v | awk '{print $2}' | cut -d'p' -f1)
        echo "Now using Ruby: $CURRENT_RUBY"
    else
        echo -e "${YELLOW}⚠️  Proceeding with Ruby $CURRENT_RUBY (may have compatibility issues)${NC}"
        # Update .ruby-version to current
        echo "$CURRENT_RUBY" > .ruby-version
    fi
fi

echo ""

# Step 2: Install dependencies
echo -e "${BLUE}Step 2: Installing dependencies...${NC}"
if ! command -v bundle &> /dev/null; then
    echo "Installing bundler..."
    gem install bundler
fi

echo "Running bundle install..."
bundle install

echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 3: Check for PostgreSQL
echo -e "${BLUE}Step 3: Checking database...${NC}"
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}⚠️  PostgreSQL not found${NC}"
    echo "Install with: brew install postgresql@14"
    echo "Then run: brew services start postgresql@14"
    echo ""
    read -p "Press Enter after installing PostgreSQL..."
fi

# Check if PostgreSQL is running
if pg_isready &> /dev/null; then
    echo -e "${GREEN}✓ PostgreSQL is running${NC}"
else
    echo -e "${YELLOW}⚠️  PostgreSQL is not running${NC}"
    echo "Start with: brew services start postgresql@14"
    echo ""
    read -p "Press Enter after starting PostgreSQL..."
fi

echo ""

# Step 4: Setup database
echo -e "${BLUE}Step 4: Setting up database...${NC}"

# Check if database exists
if rails db:version &> /dev/null; then
    echo -e "${YELLOW}Database already exists${NC}"
    read -p "Drop and recreate? (y/N): " drop_db
    if [ "$drop_db" = "y" ] || [ "$drop_db" = "Y" ]; then
        echo "Dropping database..."
        rails db:drop
        echo "Creating database..."
        rails db:create
        echo "Running migrations..."
        rails db:migrate
    else
        echo "Running migrations..."
        rails db:migrate
    fi
else
    echo "Creating database..."
    rails db:create
    echo "Running migrations..."
    rails db:migrate
fi

echo -e "${GREEN}✓ Database ready${NC}"
echo ""

# Step 5: Load FHIR setup
echo -e "${BLUE}Step 5: Loading FHIR namespaces and sample data...${NC}"
rails runner "load 'db/seeds/fhir_setup.rb'"
echo -e "${GREEN}✓ FHIR setup complete${NC}"
echo ""

# Step 6: Start server
echo -e "${GREEN}===================================="
echo "✅ Setup Complete!"
echo "====================================${NC}"
echo ""
echo "Your Violet Rails EHR is ready!"
echo ""
echo -e "${BLUE}To start the server:${NC}"
echo "  rails server"
echo ""
echo -e "${BLUE}Then test the API:${NC}"
echo "  curl http://localhost:3000/fhir/metadata | jq"
echo "  curl http://localhost:3000/fhir/Patient | jq"
echo ""
echo -e "${BLUE}Or run the interactive test:${NC}"
echo "  ./test_flows.sh"
echo ""
read -p "Start server now? (Y/n): " start_server

if [ "$start_server" != "n" ] && [ "$start_server" != "N" ]; then
    echo ""
    echo -e "${GREEN}🚀 Starting Rails server...${NC}"
    echo "Server will be available at: http://localhost:3000"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo ""
    rails server
else
    echo ""
    echo "Run 'rails server' when ready!"
fi
