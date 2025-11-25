#!/bin/bash
################################################################################
# Linux Hardening Framework - Universal Rule Executor
# Reads YAML rules and applies hardening configurations
# Version: 1.0.0
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global counters
TOTAL_RULES=0
PASSED_RULES=0
FAILED_RULES=0
SKIPPED_RULES=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo ""
    echo "================================================================================"
    echo "$1"
    echo "================================================================================"
}

# Check if yq is installed
check_yq() {
    if ! command -v yq &> /dev/null; then
        log_error "yq is not installed. Please install it first:"
        log_info "wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq"
        log_info "chmod +x /usr/bin/yq"
        exit 1
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Execute a rule
execute_rule() {
    local rule_id="$1"
    local description="$2"
    local severity="$3"
    local apply_cmd="$4"
    local verify_cmd="$5"
    local rollback_cmd="$6"
    local notes="$7"
    
    ((TOTAL_RULES++))
    
    log_section "Rule: $rule_id"
    log_info "Description: $description"
    log_info "Severity: $severity"
    log_info "Notes: $notes"
    
    # Apply the rule
    log_info "Applying configuration..."
    if eval "$apply_cmd" 2>&1; then
        log_success "Configuration applied"
    else
        log_warning "Configuration application had warnings"
    fi
    
    # Verify the rule
    log_info "Verifying configuration..."
    local verify_result
    verify_result=$(eval "$verify_cmd" 2>&1 || echo "FAIL")
    
    if [[ "$verify_result" == *"PASS"* ]]; then
        log_success "✓ Rule $rule_id PASSED"
        ((PASSED_RULES++))
        return 0
    elif [[ "$verify_result" == *"SKIP"* ]]; then
        log_warning "⊘ Rule $rule_id SKIPPED (not applicable)"
        ((SKIPPED_RULES++))
        return 0
    else
        log_error "✗ Rule $rule_id FAILED"
        log_warning "Verification result: $verify_result"
        
        # Attempt rollback
        log_warning "Attempting rollback..."
        if eval "$rollback_cmd" 2>&1; then
            log_info "Rollback completed"
        else
            log_warning "Rollback had issues"
        fi
        
        ((FAILED_RULES++))
        return 1
    fi
}

# Main execution function
main() {
    local rules_file="${1:-}"
    
    if [[ -z "$rules_file" ]]; then
        log_error "Usage: $0 <rules.yaml>"
        exit 1
    fi
    
    if [[ ! -f "$rules_file" ]]; then
        log_error "Rules file not found: $rules_file"
        exit 1
    fi
    
    check_yq
    check_root
    
    # Parse module info
    local module_name module_id
    module_name=$(yq eval '.module_name' "$rules_file")
    module_id=$(yq eval '.module_id' "$rules_file")
    
    log_section "Starting Hardening Module: $module_name ($module_id)"
    log_info "Rules file: $rules_file"
    log_info "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Get total number of rules
    local rule_count
    rule_count=$(yq eval '.rules | length' "$rules_file")
    log_info "Total rules to process: $rule_count"
    echo ""
    
    # Process each rule
    for ((i=0; i<rule_count; i++)); do
        local rule_id description severity apply_cmd verify_cmd rollback_cmd notes
        
        rule_id=$(yq eval ".rules[$i].id" "$rules_file")
        description=$(yq eval ".rules[$i].description" "$rules_file")
        severity=$(yq eval ".rules[$i].severity" "$rules_file")
        apply_cmd=$(yq eval ".rules[$i].apply" "$rules_file")
        verify_cmd=$(yq eval ".rules[$i].verify" "$rules_file")
        rollback_cmd=$(yq eval ".rules[$i].rollback" "$rules_file")
        notes=$(yq eval ".rules[$i].notes" "$rules_file")
        
        # Execute the rule (continue even if it fails)
        execute_rule "$rule_id" "$description" "$severity" "$apply_cmd" "$verify_cmd" "$rollback_cmd" "$notes" || true
        
        sleep 0.5  # Brief pause between rules
    done
    
    # Print summary
    log_section "Module Execution Summary"
    log_info "Module: $module_name ($module_id)"
    log_info "Total Rules: $TOTAL_RULES"
    log_success "Passed: $PASSED_RULES"
    log_error "Failed: $FAILED_RULES"
    log_warning "Skipped: $SKIPPED_RULES"
    
    local success_rate=0
    if [[ $TOTAL_RULES -gt 0 ]]; then
        success_rate=$(( (PASSED_RULES * 100) / TOTAL_RULES ))
    fi
    log_info "Success Rate: ${success_rate}%"
    
    # Return exit code based on results
    if [[ $FAILED_RULES -eq 0 ]]; then
        log_success "Module completed successfully!"
        return 0
    else
        log_warning "Module completed with failures"
        return 1
    fi
}

# Execute main function
main "$@"
