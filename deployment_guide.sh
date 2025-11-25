#!/bin/bash
################################################################################
# Linux Hardening Framework - Complete Deployment Script
# This script sets up the entire hardening framework structure
################################################################################

set -e

echo "=========================================="
echo "Linux Hardening Framework Deployment"
echo "=========================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root" 
   exit 1
fi

# Create directory structure
BASE_DIR="/opt/linux-hardening"
echo "[1/6] Creating directory structure in $BASE_DIR..."
mkdir -p "$BASE_DIR"/{rules,scripts,logs,reports}

# Install yq if not present
echo "[2/6] Checking and installing prerequisites..."
if ! command -v yq &> /dev/null; then
    echo "Installing yq..."
    wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
    chmod +x /usr/bin/yq
    echo "✓ yq installed"
else
    echo "✓ yq already installed"
fi

# Create the bash executor script
echo "[3/6] Creating universal bash executor..."
cat > "$BASE_DIR/scripts/executor.sh" <<'EXECUTOR_EOF'
#!/bin/bash
################################################################################
# Linux Hardening Framework - Universal Rule Executor
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global counters
TOTAL_RULES=0
PASSED_RULES=0
FAILED_RULES=0
SKIPPED_RULES=0

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() {
    echo ""
    echo "================================================================================"
    echo "$1"
    echo "================================================================================"
}

check_yq() {
    if ! command -v yq &> /dev/null; then
        log_error "yq is not installed"
        exit 1
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

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
    
    log_info "Applying configuration..."
    if eval "$apply_cmd" 2>&1; then
        log_success "Configuration applied"
    else
        log_warning "Configuration application had warnings"
    fi
    
    log_info "Verifying configuration..."
    local verify_result
    verify_result=$(eval "$verify_cmd" 2>&1 || echo "FAIL")
    
    if [[ "$verify_result" == *"PASS"* ]]; then
        log_success "✓ Rule $rule_id PASSED"
        ((PASSED_RULES++))
        return 0
    elif [[ "$verify_result" == *"SKIP"* ]]; then
        log_warning "⊘ Rule $rule_id SKIPPED"
        ((SKIPPED_RULES++))
        return 0
    else
        log_error "✗ Rule $rule_id FAILED"
        log_warning "Attempting rollback..."
        eval "$rollback_cmd" 2>&1 || true
        ((FAILED_RULES++))
        return 1
    fi
}

main() {
    local rules_file="${1:-}"
    
    if [[ -z "$rules_file" ]] || [[ ! -f "$rules_file" ]]; then
        log_error "Usage: $0 <rules.yaml>"
        exit 1
    fi
    
    check_yq
    check_root
    
    local module_name module_id rule_count
    module_name=$(yq eval '.module_name' "$rules_file")
    module_id=$(yq eval '.module_id' "$rules_file")
    rule_count=$(yq eval '.rules | length' "$rules_file")
    
    log_section "Starting: $module_name ($module_id)"
    log_info "Rules file: $rules_file"
    log_info "Total rules: $rule_count"
    echo ""
    
    for ((i=0; i<rule_count; i++)); do
        local rule_id description severity apply_cmd verify_cmd rollback_cmd notes
        
        rule_id=$(yq eval ".rules[$i].id" "$rules_file")
        description=$(yq eval ".rules[$i].description" "$rules_file")
        severity=$(yq eval ".rules[$i].severity" "$rules_file")
        apply_cmd=$(yq eval ".rules[$i].apply" "$rules_file")
        verify_cmd=$(yq eval ".rules[$i].verify" "$rules_file")
        rollback_cmd=$(yq eval ".rules[$i].rollback" "$rules_file")
        notes=$(yq eval ".rules[$i].notes" "$rules_file")
        
        execute_rule "$rule_id" "$description" "$severity" "$apply_cmd" "$verify_cmd" "$rollback_cmd" "$notes" || true
        sleep 0.5
    done
    
    log_section "Module Execution Summary"
    log_info "Module: $module_name"
    log_info "Total: $TOTAL_RULES"
    log_success "Passed: $PASSED_RULES"
    log_error "Failed: $FAILED_RULES"
    log_warning "Skipped: $SKIPPED_RULES"
    
    if [[ $FAILED_RULES -eq 0 ]]; then
        log_success "Module completed successfully!"
        return 0
    else
        log_warning "Module completed with failures"
        return 1
    fi
}

main "$@"
EXECUTOR_EOF

chmod +x "$BASE_DIR/scripts/executor.sh"
echo "✓ Bash executor created"

# Create symbolic links for each module
echo "[4/6] Creating module executor scripts..."
for module in 01_filesystem 02_package_management 03_services 04_network 05_firewall 06_access_control 07_user_accounts 08_logging_auditing 09_system_maintenance; do
    ln -sf "$BASE_DIR/scripts/executor.sh" "$BASE_DIR/scripts/${module}.sh"
done
echo "✓ Module scripts linked"

# Copy the Python main controller
echo "[5/6] Installing Python main controller..."
cat > "$BASE_DIR/harden.py" <<'PYTHON_EOF'
#!/usr/bin/env python3
"""Linux System Hardening Framework - Main Controller"""

import os
import sys
import subprocess
import platform
import logging
from datetime import datetime
from pathlib import Path
import json

class HardeningFramework:
    def __init__(self):
        self.modules = [
            "01_filesystem", "02_package_management", "03_services",
            "04_network", "05_firewall", "06_access_control",
            "07_user_accounts", "08_logging_auditing", "09_system_maintenance"
        ]
        self.base_dir = Path(__file__).parent
        self.rules_dir = self.base_dir / "rules"
        self.scripts_dir = self.base_dir / "scripts"
        self.logs_dir = self.base_dir / "logs"
        self.reports_dir = self.base_dir / "reports"
        
        log_file = self.logs_dir / f"hardening_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[logging.FileHandler(log_file), logging.StreamHandler(sys.stdout)]
        )
        self.logger = logging.getLogger(__name__)
        self.results = {"start_time": datetime.now().isoformat(), "modules": {}}
    
    def detect_os(self):
        os_info = {"system": platform.system(), "release": platform.release()}
        try:
            with open('/etc/os-release', 'r') as f:
                for line in f:
                    if line.startswith('ID='): os_info['distro'] = line.split('=')[1].strip().strip('"')
                    elif line.startswith('VERSION_ID='): os_info['distro_version'] = line.split('=')[1].strip().strip('"')
        except: os_info['distro'] = 'unknown'
        return os_info
    
    def check_prerequisites(self):
        if subprocess.run(['which', 'yq'], capture_output=True).returncode != 0:
            self.logger.error("yq not installed")
            return False
        if os.geteuid() != 0:
            self.logger.error("Must run as root")
            return False
        return True
    
    def execute_module(self, module_name):
        self.logger.info(f"{'='*80}")
        self.logger.info(f"Executing: {module_name}")
        self.logger.info(f"{'='*80}")
        
        script = self.scripts_dir / f"{module_name}.sh"
        rules = self.rules_dir / f"{module_name}.yaml"
        
        if not script.exists() or not rules.exists():
            self.logger.error(f"Missing files for {module_name}")
            return False
        
        try:
            result = subprocess.run(['bash', str(script), str(rules)], 
                                  capture_output=True, text=True, timeout=600)
            if result.stdout: self.logger.info(result.stdout)
            if result.stderr: self.logger.warning(result.stderr)
            
            self.results["modules"][module_name] = {
                "status": "success" if result.returncode == 0 else "failed",
                "return_code": result.returncode
            }
            return result.returncode == 0
        except Exception as e:
            self.logger.error(f"Error: {e}")
            self.results["modules"][module_name] = {"status": "error", "error": str(e)}
            return False
    
    def run(self, specific_module=None):
        self.logger.info("Linux System Hardening Framework v1.0.0")
        if not self.check_prerequisites(): return False
        
        modules = [specific_module] if specific_module else self.modules
        success = sum(self.execute_module(m) for m in modules if m in self.modules)
        
        self.results["end_time"] = datetime.now().isoformat()
        report = self.reports_dir / f"report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report, 'w') as f: json.dump(self.results, f, indent=2)
        
        self.logger.info(f"\nCompleted: {success}/{len(modules)} succeeded")
        self.logger.info(f"Report: {report}")
        return success == len(modules)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='Linux Hardening Framework')
    parser.add_argument('-m', '--module', help='Run specific module')
    parser.add_argument('-l', '--list', action='store_true', help='List modules')
    args = parser.parse_args()
    
    fw = HardeningFramework()
    if args.list:
        print("Available modules:")
        for m in fw.modules: print(f"  - {m}")
    else:
        sys.exit(0 if fw.run(args.module) else 1)
PYTHON_EOF

chmod +x "$BASE_DIR/harden.py"
echo "✓ Python controller installed"

# Create a quick start script
echo "[6/6] Creating quick start script..."
cat > "$BASE_DIR/quickstart.sh" <<'QUICKSTART_EOF'
#!/bin/bash
echo "==========================================="
echo "Linux Hardening Framework - Quick Start"
echo "==========================================="
echo ""
echo "IMPORTANT: This will apply hardening to your system."
echo "Make sure you have:"
echo "  1. A backup of your system"
echo "  2. Console/physical access (in case SSH is affected)"
echo "  3. Reviewed the rules in the rules/ directory"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

cd "$(dirname "$0")"

echo ""
echo "Starting hardening process..."
echo ""

python3 harden.py

echo ""
echo "==========================================="
echo "Hardening Complete!"
echo "==========================================="
echo ""
echo "CRITICAL: Test SSH access in a NEW terminal before logging out!"
echo "Check logs in: logs/"
echo "Check reports in: reports/"
echo ""
QUICKSTART_EOF

chmod +x "$BASE_DIR/quickstart.sh"
echo "✓ Quick start script created"

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Framework installed in: $BASE_DIR"
echo ""
echo "Next steps:"
echo "  1. Copy your YAML rule files to: $BASE_DIR/rules/"
echo "     - 01_filesystem.yaml"
echo "     - 02_package_management.yaml"
echo "     - 03_services.yaml"
echo "     - 04_network.yaml"
echo "     - 05_firewall.yaml"
echo "     - 06_access_control.yaml"
echo "     - 07_user_accounts.yaml"
echo "     - 08_logging_auditing.yaml"
echo "     - 09_system_maintenance.yaml"
echo ""
echo "  2. Review and customize rules for your environment"
echo ""
echo "  3. Run hardening:"
echo "     cd $BASE_DIR"
echo "     ./quickstart.sh              # Interactive mode"
echo "     # OR"
echo "     python3 harden.py            # Run all modules"
echo "     python3 harden.py -m 01_filesystem  # Run specific module"
echo "     python3 harden.py -l         # List modules"
echo ""
echo "  4. Test a single module:"
echo "     bash scripts/01_filesystem.sh rules/01_filesystem.yaml"
echo ""
echo "WARNING: Always test in a non-production environment first!"
echo "=========================================="
