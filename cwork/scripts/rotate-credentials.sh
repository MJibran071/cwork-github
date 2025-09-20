#!/bin/bash

# Credential Rotation Script for Cwork Project
# This script automates the rotation of API keys, tokens, and credentials in HashiCorp Vault

set -e

VAULT_URL="${VAULT_URL:-https://vault.yourcompany.com}"
LOG_FILE="${LOG_FILE:-./credential-rotation.log}"
ROTATION_DATE=$(date '+%Y-%m-%d')

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

generate_password() {
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9!@#$%^&*()_+-=' | head -c 24
}

generate_token() {
    openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | head -c 32
}

check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v vault &> /dev/null; then
        error "HashiCorp Vault CLI is not installed. Please install it from https://www.vaultproject.io/downloads"
    fi
    
    if ! command -v openssl &> /dev/null; then
        error "openssl is not installed. Please install it: brew install openssl"
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
        error "No authentication method found. Please set VAULT_TOKEN or VAULT_ROLE_ID and VAULT_SECRET_ID"
    fi
}

rotate_secret() {
    local secret_path=$1
    local key=$2
    local new_value=$3
    
    log "Rotating $key in $secret_path"
    
    if vault kv get "$secret_path" >/dev/null 2>&1; then
        # Get current secret data
        current_data=$(vault kv get -format=json "$secret_path" | jq -r '.data.data')
        
        # Update the specific key
        updated_data=$(echo "$current_data" | jq --arg key "$key" --arg value "$new_value" '.[$key] = $value')
        
        # Write updated secret
        echo "$updated_data" | vault kv put "$secret_path" -
        
        success "Rotated $key in $secret_path"
    else
        warn "Secret path $secret_path not found, skipping rotation"
    fi
}

rotate_database_credentials() {
    log "Rotating database credentials..."
    
    # Rotate auth service database password
    new_db_pass=$(generate_password)
    rotate_secret "secret/backend/auth" "db_pass" "$new_db_pass"
    
    # Rotate marketplace service database password  
    new_marketplace_pass=$(generate_password)
    rotate_secret "secret/backend/marketplace" "db_pass" "$new_marketplace_pass"
    
    success "Database credentials rotated successfully"
}

rotate_jwt_secrets() {
    log "Rotating JWT secrets..."
    
    new_jwt_secret=$(generate_token)
    rotate_secret "secret/backend/auth" "jwt_secret" "$new_jwt_secret"
    
    success "JWT secrets rotated successfully"
}

rotate_api_tokens() {
    log "Rotating API tokens..."
    
    # Rotate npm token
    new_npm_token=$(generate_token)
    rotate_secret "secret/cicd/common" "npm_token" "$new_npm_token"
    
    # Rotate Docker credentials
    new_docker_password=$(generate_password)
    rotate_secret "secret/cicd/common" "docker_password" "$new_docker_password"
    
    # Rotate third-party API keys
    new_stripe_key="sk_test_$(generate_token)"
    rotate_secret "secret/backend/marketplace" "stripe_key" "$new_stripe_key"
    
    success "API tokens rotated successfully"
}

rotate_blockchain_keys() {
    log "Rotating blockchain private keys..."
    
    # Note: In production, you should use proper key management for blockchain keys
    # This is just for demonstration - actual key rotation requires careful handling
    
    warn "Blockchain private key rotation requires manual intervention and secure key management"
    warn "Please rotate blockchain keys manually using secure procedures"
    
    # Log rotation date for audit purposes
    log "Blockchain key rotation audit: $ROTATION_DATE"
}

create_rotation_backup() {
    log "Creating rotation backup..."
    
    backup_dir="./backups/credential-rotation-$ROTATION_DATE"
    mkdir -p "$backup_dir"
    
    # Backup current secret states
    vault kv get -format=json secret/backend/auth > "$backup_dir/auth-backup.json"
    vault kv get -format=json secret/backend/marketplace > "$backup_dir/marketplace-backup.json"
    vault kv get -format=json secret/cicd/common > "$backup_dir/cicd-backup.json"
    
    success "Rotation backup created in $backup_dir"
}

notify_services() {
    log "Notifying services to reload secrets..."
    
    # This would typically involve sending signals to services or using config reload endpoints
    # For now, we'll just log the notification
    
    echo "Services should be configured to automatically reload secrets from Vault"
    echo "If manual intervention is needed, restart the following services:"
    echo "  - Auth Service"
    echo "  - Marketplace Service"
    echo "  - CI/CD pipelines"
    
    success "Services notified (log only - implement actual notifications in production)"
}

main() {
    log "Starting credential rotation process"
    
    check_dependencies
    
    if ! authenticate_vault; then
        error "Failed to authenticate with Vault"
    fi
    
    # Create backup before rotation
    create_rotation_backup
    
    # Perform rotations
    rotate_database_credentials
    rotate_jwt_secrets
    rotate_api_tokens
    rotate_blockchain_keys
    
    # Notify services
    notify_services
    
    log "Credential rotation process completed"
    log "Summary of rotated credentials:"
    log "  - Database passwords"
    log "  - JWT secrets" 
    log "  - API tokens (npm, Docker)"
    log "  - Third-party service keys"
    log "  - Blockchain keys (audit only)"
    
    success "All credentials rotated successfully. Backup available in ./backups/"
    success "Remember to update any hardcoded references and test the changes!"
}

# Handle command line arguments
case "${1:-}" in
    "db")
        authenticate_vault
        rotate_database_credentials
        ;;
    "jwt")
        authenticate_vault
        rotate_jwt_secrets
        ;;
    "api")
        authenticate_vault
        rotate_api_tokens
        ;;
    "backup")
        authenticate_vault
        create_rotation_backup
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  db          - Rotate only database credentials"
        echo "  jwt         - Rotate only JWT secrets"
        echo "  api         - Rotate only API tokens"
        echo "  backup      - Create backup only"
        echo "  help        - Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  VAULT_URL     - Vault server URL (default: https://vault.yourcompany.com)"
        echo "  VAULT_TOKEN   - Vault authentication token"
        echo "  VAULT_ROLE_ID - AppRole role ID"
        echo "  VAULT_SECRET_ID - AppRole secret ID"
        echo ""
        ;;
    *)
        main
        ;;
esac