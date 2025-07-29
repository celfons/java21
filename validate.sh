#!/bin/bash
# Complete validation script for MongoDB Kafka Connector Example

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MongoDB Kafka Connector Example - Validation Test ===${NC}"
echo "$(date)"
echo

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate JSON files
validate_json() {
    local file=$1
    echo -n "Validating JSON file $file... "
    
    if jq . "$file" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Valid${NC}"
        return 0
    else
        echo -e "${RED}✗ Invalid${NC}"
        return 1
    fi
}

# Function to check script syntax
validate_script() {
    local script=$1
    echo -n "Validating script $script... "
    
    if bash -n "$script" 2>/dev/null; then
        echo -e "${GREEN}✓ Valid syntax${NC}"
        return 0
    else
        echo -e "${RED}✗ Syntax error${NC}"
        return 1
    fi
}

# Function to check Docker Compose configuration
validate_docker_compose() {
    echo -n "Validating Docker Compose configuration... "
    
    if docker-compose config --quiet 2>/dev/null; then
        echo -e "${GREEN}✓ Valid${NC}"
        return 0
    else
        echo -e "${RED}✗ Invalid${NC}"
        return 1
    fi
}

# Function to check required tools
check_prerequisites() {
    echo -e "${BLUE}=== Prerequisites Check ===${NC}"
    local all_good=true
    
    # Check Docker
    if command_exists docker; then
        echo -e "Docker: ${GREEN}✓ Installed ($(docker --version | cut -d' ' -f3 | tr -d ','))${NC}"
    else
        echo -e "Docker: ${RED}✗ Not installed${NC}"
        all_good=false
    fi
    
    # Check Docker Compose
    if command_exists docker-compose; then
        echo -e "Docker Compose: ${GREEN}✓ Installed ($(docker-compose --version | cut -d' ' -f3 | tr -d ','))${NC}"
    else
        echo -e "Docker Compose: ${RED}✗ Not installed${NC}"
        all_good=false
    fi
    
    # Check jq
    if command_exists jq; then
        echo -e "jq: ${GREEN}✓ Installed${NC}"
    else
        echo -e "jq: ${RED}✗ Not installed${NC}"
        all_good=false
    fi
    
    # Check curl
    if command_exists curl; then
        echo -e "curl: ${GREEN}✓ Installed${NC}"
    else
        echo -e "curl: ${RED}✗ Not installed${NC}"
        all_good=false
    fi
    
    # Check netcat
    if command_exists nc; then
        echo -e "netcat: ${GREEN}✓ Installed${NC}"
    else
        echo -e "netcat: ${RED}✗ Not installed${NC}"
        all_good=false
    fi
    
    echo
    if $all_good; then return 0; else return 1; fi
}

# Function to validate file structure
validate_structure() {
    echo -e "${BLUE}=== File Structure Validation ===${NC}"
    local all_good=true
    
    local required_files=(
        "docker-compose.yml"
        "Dockerfile"
        ".env.example"
        "Makefile"
        "README.md"
        "LICENSE"
        ".gitignore"
        "config/kafka-connect/mongodb-source-connector.json"
        "config/kafka-connect/connect-log4j.properties"
        "config/mongodb/replica-init.js"
        "scripts/health-check.sh"
        "scripts/init-replica.sh"
        "scripts/setup-connector.sh"
        "scripts/sample-data.js"
        "docs/SETUP.md"
        "docs/ATLAS_SETUP.md"
        "docs/TROUBLESHOOTING.md"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "$file: ${GREEN}✓ Exists${NC}"
        else
            echo -e "$file: ${RED}✗ Missing${NC}"
            all_good=false
        fi
    done
    
    echo
    if $all_good; then return 0; else return 1; fi
}

# Function to validate configuration files
validate_configs() {
    echo -e "${BLUE}=== Configuration Validation ===${NC}"
    local all_good=true
    
    # Validate JSON files
    local json_files=(
        "config/kafka-connect/mongodb-source-connector.json"
    )
    
    for file in "${json_files[@]}"; do
        if ! validate_json "$file"; then
            all_good=false
        fi
    done
    
    # Validate Docker Compose
    if ! validate_docker_compose; then
        all_good=false
    fi
    
    echo
    if $all_good; then return 0; else return 1; fi
}

# Function to validate scripts
validate_scripts() {
    echo -e "${BLUE}=== Script Validation ===${NC}"
    local all_good=true
    
    local scripts=(
        "scripts/health-check.sh"
        "scripts/init-replica.sh"
        "scripts/setup-connector.sh"
    )
    
    for script in "${scripts[@]}"; do
        if ! validate_script "$script"; then
            all_good=false
        fi
        
        # Check if script is executable
        if [ -x "$script" ]; then
            echo -e "$script permissions: ${GREEN}✓ Executable${NC}"
        else
            echo -e "$script permissions: ${RED}✗ Not executable${NC}"
            all_good=false
        fi
    done
    
    echo
    if $all_good; then return 0; else return 1; fi
}

# Function to validate Makefile
validate_makefile() {
    echo -e "${BLUE}=== Makefile Validation ===${NC}"
    
    if [ -f "Makefile" ]; then
        echo -n "Makefile syntax check... "
        if make -n help >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Valid${NC}"
        else
            echo -e "${RED}✗ Invalid${NC}"
            return 1
        fi
        
        echo -n "Makefile targets check... "
        local required_targets=("help" "build" "up" "down" "setup" "clean")
        local missing_targets=()
        
        for target in "${required_targets[@]}"; do
            if ! make -n "$target" >/dev/null 2>&1; then
                missing_targets+=("$target")
            fi
        done
        
        if [ ${#missing_targets[@]} -eq 0 ]; then
            echo -e "${GREEN}✓ All required targets present${NC}"
        else
            echo -e "${RED}✗ Missing targets: ${missing_targets[*]}${NC}"
            return 1
        fi
    else
        echo -e "Makefile: ${RED}✗ Missing${NC}"
        return 1
    fi
    
    echo
    return 0
}

# Function to validate documentation
validate_docs() {
    echo -e "${BLUE}=== Documentation Validation ===${NC}"
    local all_good=true
    
    local docs=(
        "README.md"
        "docs/SETUP.md"
        "docs/ATLAS_SETUP.md"
        "docs/TROUBLESHOOTING.md"
    )
    
    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            local word_count=$(wc -w < "$doc")
            if [ "$word_count" -gt 100 ]; then
                echo -e "$doc: ${GREEN}✓ Comprehensive ($word_count words)${NC}"
            else
                echo -e "$doc: ${YELLOW}⚠ Brief ($word_count words)${NC}"
            fi
        else
            echo -e "$doc: ${RED}✗ Missing${NC}"
            all_good=false
        fi
    done
    
    echo
    if $all_good; then return 0; else return 1; fi
}

# Function to check environment setup
validate_environment() {
    echo -e "${BLUE}=== Environment Validation ===${NC}"
    
    # Check if .env.example exists
    if [ -f ".env.example" ]; then
        echo -e ".env.example: ${GREEN}✓ Exists${NC}"
        
        # Check if .env was created
        if [ -f ".env" ]; then
            echo -e ".env: ${GREEN}✓ Created${NC}"
        else
            echo -e ".env: ${YELLOW}⚠ Not created (will be created on setup)${NC}"
        fi
        
        # Check essential variables
        local required_vars=(
            "MONGO_INITDB_ROOT_USERNAME"
            "MONGO_INITDB_ROOT_PASSWORD"
            "KAFKA_ADVERTISED_LISTENERS"
            "CONNECT_BOOTSTRAP_SERVERS"
        )
        
        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" .env.example; then
                echo -e "Variable $var: ${GREEN}✓ Defined${NC}"
            else
                echo -e "Variable $var: ${RED}✗ Missing${NC}"
                return 1
            fi
        done
    else
        echo -e ".env.example: ${RED}✗ Missing${NC}"
        return 1
    fi
    
    echo
    return 0
}

# Main validation function
main() {
    local overall_status=true
    
    # Run all validation checks
    if ! check_prerequisites; then
        overall_status=false
    fi
    
    if ! validate_structure; then
        overall_status=false
    fi
    
    if ! validate_configs; then
        overall_status=false
    fi
    
    if ! validate_scripts; then
        overall_status=false
    fi
    
    if ! validate_makefile; then
        overall_status=false
    fi
    
    if ! validate_docs; then
        overall_status=false
    fi
    
    if ! validate_environment; then
        overall_status=false
    fi
    
    # Summary
    echo -e "${BLUE}=== Validation Summary ===${NC}"
    
    if $overall_status; then
        echo -e "${GREEN}✅ All validations passed!${NC}"
        echo -e "${BLUE}Ready for production deployment.${NC}"
        echo
        echo -e "${YELLOW}Next steps:${NC}"
        echo "1. Run: make dev-setup"
        echo "2. Access Kafka UI: http://localhost:8080"
        echo "3. Access MongoDB Express: http://localhost:8081"
        echo "4. Check status: make status"
        exit 0
    else
        echo -e "${RED}❌ Some validations failed!${NC}"
        echo -e "${YELLOW}Please fix the issues above before proceeding.${NC}"
        exit 1
    fi
}

# Check if running from correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Please run this script from the project root directory${NC}"
    exit 1
fi

# Run validation
main