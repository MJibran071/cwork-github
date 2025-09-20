#!/bin/bash

# Secrets Management Script for Local Development
# This script helps developers pull secrets from HashiCorp Vault for local development

set -e

VAULT_URL="${VAULT_URL:-https://vault.yourcompany.com}"
SECRETS_DIR="${SECRETS_DIR:-./.secrets}"
LOG_FILE="${LOG_FILE:-./secrets-pull.log}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v vault &> /dev/null; then
        error "HashiCorp Vault CLI is not installed. Please install it from https://www.vaultproject.io/downloads"
    fi
    
    if ! command -v jq &> /dev/null; then
        error "jq is not installed. Please install it: brew install jq"
    fi
    
    success "All dependencies are installed"
}

authenticate_vault() {
    log "Authenticating with Vault at $VAULT_URL"
    
    # Check if we already have a valid token
    if vault token lookup >/dev/null 2>&1; then
        success "Using existing Vault token"
        return 0
    fi
    
    # Try different authentication methods
    if [ -n "$VAULT_TOKEN" ]; then
        export VAULT_TOKEN
        success "Using VAULT_TOKEN environment variable"
    elif [ -n "$VAULT_ROLE_ID" ] && [ -n "$VAULT_SECRET_ID" ]; then
        vault write auth/approle/login role_id="$VAULT_ROLE_ID" secret_id="$VAULT_SECRET_ID" > /dev/null
        success "Authenticated using AppRole"
    else
        warn "No authentication method found. Please authenticate manually:"
        warn "  vault login -method=userpass username=your_username"
        warn "Or set VAULT_TOKEN, VAULT_ROLE_ID, and VAULT_SECRET_ID environment variables"
        return 1
    fi
}

pull_secrets() {
    local service=$1
    local secret_path=$2
    local output_file="$SECRETS_DIR/$service.env"
    
    log "Pulling secrets for $service from $secret_path"
    
    mkdir -p "$SECRETS_DIR"
    
    if vault kv get -format=json "$secret_path" > /dev/null 2>&1; then
        vault kv get -format=json "$secret_path" | jq -r '.data.data | to_entries | .[] | "\(.key)=\(.value)"' > "$output_file"
        
        if [ -s "$output_file" ]; then
            success "Secrets pulled successfully to $output_file"
            echo "Contents of $output_file:"
            cat "$output_file"
            echo ""
        else
            warn "No secrets found or empty response for $secret_path"
        fi
    else
        warn "Secret path $secret_path not found or access denied"
    fi
}

generate_env_template() {
    local service=$1
    local template_file="$SECRETS_DIR/$service.env.template"
    
    log "Generating environment template for $service"
    
    cat > "$template_file" << EOF
# $service Environment Variables Template
# Copy this file to .env and fill in the values
# Alternatively, use pull-secrets.sh to pull from Vault

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=your_username
DB_PASS=your_password
DB_NAME=${service}_db

# Application Secrets
JWT_SECRET=your_jwt_secret_here
ENCRYPTION_KEY=your_encryption_key_here

# API Keys
STRIPE_KEY=sk_test_your_stripe_key
SENDGRID_KEY=SG.your_sendgrid_key

# URLs
BACKEND_URL=http://localhost:3000
FRONTEND_URL=http://localhost:3001
EOF

    success "Template generated at $template_file"
}

main() {
    log "Starting secrets pull process"
    
    check_dependencies
    
    if ! authenticate_vault; then
        error "Failed to authenticate with Vault"
    fi
    
    # Create secrets directory
    mkdir -p "$SECRETS_DIR"
    
    # Pull secrets for different services
    services=(
        "backend/auth:secret/data/backend/auth"
        "backend/marketplace:secret/data/backend/marketplace"
        "contracts/ethereum:secret/data/contracts/ethereum"
        "contracts/solana:secret/data/contracts/solana"
        "mobile/app:secret/data/mobile/app"
        "cicd/common:secret/data/cicd/common"
    )
    
    for service_config in "${services[@]}"; do
        IFS=':' read -r service secret_path <<< "$service_config"
        pull_secrets "$service" "$secret_path"
    done
    
    # Generate templates for services that might not have secrets in Vault yet
    generate_env_template "auth-service"
    generate_env_template "marketplace-service"
    generate_env_template "mobile-app"
    
    log "Secrets pull process completed"
    log "Summary of pulled secrets:"
    find "$SECRETS_DIR" -name "*.env" -exec echo "  - {}" \;
    
    success "To use these secrets, source the appropriate .env file:"
    success "  source $SECRETS_DIR/backend/auth.env"
    success "Or copy to your service's .env file:"
    success "  cp $SECRETS_DIR/backend/auth.env backend/auth-service/.env"
}

# Handle command line arguments
case "${1:-}" in
    "auth")
        authenticate_vault
        ;;
    "pull")
        service="${2:-}"
        secret_path="${3:-}"
        if [ -n "$service" ] && [ -n "$secret_path" ]; then
            pull_secrets "$service" "$secret_path"
        else
            error "Usage: $0 pull <service> <secret_path>"
        fi
        ;;
    "template")
        service="${2:-}"
        if [ -n "$service" ]; then
            generate_env_template "$service"
        else
            error "Usage: $0 template <service>"
        fi
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  auth          - Authenticate with Vault"
        echo "  pull <service> <path> - Pull specific secrets"
        echo "  template <service> - Generate environment template"
        echo "  help          - Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  VAULT_URL     - Vault server URL (default: https://vault.yourcompany.com)"
        echo "  SECRETS_DIR   - Directory to store secrets (default: ./.secrets)"
        echo "  VAULT_TOKEN   - Vault authentication token"
        echo "  VAULT_ROLE_ID - AppRole role ID"
        echo "  VAULT_SECRET_ID - AppRole secret ID"
        echo ""
        ;;
    *)
        main
        ;;
esac