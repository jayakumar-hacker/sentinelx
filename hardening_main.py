#!/usr/bin/env python3
"""
Linux System Hardening Framework
Main Controller - Orchestrates all hardening modules
Version: 1.0.0
"""

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
            "01_filesystem",
            "02_package_management",
            "03_services",
            "04_network",
            "05_firewall",
            "06_access_control",
            "07_user_accounts",
            "08_logging_auditing",
            "09_system_maintenance"
        ]
        
        self.base_dir = Path(__file__).parent
        self.rules_dir = self.base_dir / "rules"
        self.scripts_dir = self.base_dir / "scripts"
        self.logs_dir = self.base_dir / "logs"
        self.reports_dir = self.base_dir / "reports"
        
        # Create directories
        for directory in [self.rules_dir, self.scripts_dir, self.logs_dir, self.reports_dir]:
            directory.mkdir(exist_ok=True)
        
        # Setup logging
        log_file = self.logs_dir / f"hardening_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        self.results = {
            "start_time": datetime.now().isoformat(),
            "os_info": self.detect_os(),
            "modules": {}
        }
    
    def detect_os(self):
        """Detect Linux distribution and version"""
        os_info = {
            "system": platform.system(),
            "release": platform.release(),
            "version": platform.version(),
            "machine": platform.machine()
        }
        
        try:
            # Try to read os-release
            with open('/etc/os-release', 'r') as f:
                for line in f:
                    if line.startswith('ID='):
                        os_info['distro'] = line.split('=')[1].strip().strip('"')
                    elif line.startswith('VERSION_ID='):
                        os_info['distro_version'] = line.split('=')[1].strip().strip('"')
        except FileNotFoundError:
            self.logger.warning("Could not read /etc/os-release")
            os_info['distro'] = 'unknown'
        
        return os_info
    
    def check_prerequisites(self):
        """Check if required tools are installed"""
        self.logger.info("Checking prerequisites...")
        required_tools = ['yq', 'bash']
        missing_tools = []
        
        for tool in required_tools:
            if subprocess.run(['which', tool], capture_output=True).returncode != 0:
                missing_tools.append(tool)
        
        if missing_tools:
            self.logger.error(f"Missing required tools: {', '.join(missing_tools)}")
            self.logger.info("Install yq: wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq")
            return False
        
        # Check if running as root
        if os.geteuid() != 0:
            self.logger.error("This script must be run as root!")
            return False
        
        self.logger.info("Prerequisites check passed")
        return True
    
    def execute_module(self, module_name):
        """Execute a single hardening module"""
        self.logger.info(f"{'='*80}")
        self.logger.info(f"Executing module: {module_name}")
        self.logger.info(f"{'='*80}")
        
        script_path = self.scripts_dir / f"{module_name}.sh"
        rules_path = self.rules_dir / f"{module_name}.yaml"
        
        if not script_path.exists():
            self.logger.error(f"Script not found: {script_path}")
            return False
        
        if not rules_path.exists():
            self.logger.error(f"Rules file not found: {rules_path}")
            return False
        
        try:
            result = subprocess.run(
                ['bash', str(script_path), str(rules_path)],
                capture_output=True,
                text=True,
                timeout=600  # 10 minute timeout per module
            )
            
            self.logger.info(f"Module {module_name} output:")
            if result.stdout:
                self.logger.info(result.stdout)
            if result.stderr:
                self.logger.warning(result.stderr)
            
            # Parse module results
            module_results = {
                "status": "success" if result.returncode == 0 else "failed",
                "return_code": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr
            }
            
            self.results["modules"][module_name] = module_results
            
            return result.returncode == 0
            
        except subprocess.TimeoutExpired:
            self.logger.error(f"Module {module_name} timed out")
            self.results["modules"][module_name] = {"status": "timeout"}
            return False
        except Exception as e:
            self.logger.error(f"Error executing module {module_name}: {str(e)}")
            self.results["modules"][module_name] = {"status": "error", "error": str(e)}
            return False
    
    def generate_report(self):
        """Generate final hardening report"""
        self.results["end_time"] = datetime.now().isoformat()
        
        report_file = self.reports_dir / f"hardening_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        with open(report_file, 'w') as f:
            json.dump(self.results, f, indent=2)
        
        self.logger.info(f"\n{'='*80}")
        self.logger.info("HARDENING SUMMARY")
        self.logger.info(f"{'='*80}")
        self.logger.info(f"OS: {self.results['os_info'].get('distro', 'unknown')} {self.results['os_info'].get('distro_version', '')}")
        self.logger.info(f"Start Time: {self.results['start_time']}")
        self.logger.info(f"End Time: {self.results['end_time']}")
        self.logger.info(f"\nModule Results:")
        
        for module, result in self.results["modules"].items():
            status = result.get("status", "unknown")
            self.logger.info(f"  {module}: {status.upper()}")
        
        self.logger.info(f"\nDetailed report saved to: {report_file}")
    
    def run(self, specific_module=None):
        """Main execution method"""
        self.logger.info("="*80)
        self.logger.info("Linux System Hardening Framework")
        self.logger.info("Version 1.0.0")
        self.logger.info("="*80)
        
        if not self.check_prerequisites():
            return False
        
        modules_to_run = [specific_module] if specific_module else self.modules
        
        success_count = 0
        fail_count = 0
        
        for module in modules_to_run:
            if module not in self.modules:
                self.logger.error(f"Unknown module: {module}")
                continue
            
            if self.execute_module(module):
                success_count += 1
            else:
                fail_count += 1
        
        self.generate_report()
        
        self.logger.info(f"\n{'='*80}")
        self.logger.info(f"Hardening Complete: {success_count} succeeded, {fail_count} failed")
        self.logger.info(f"{'='*80}")
        
        return fail_count == 0


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Linux System Hardening Framework')
    parser.add_argument('-m', '--module', help='Run specific module only')
    parser.add_argument('-l', '--list', action='store_true', help='List available modules')
    parser.add_argument('-v', '--version', action='version', version='1.0.0')
    
    args = parser.parse_args()
    
    framework = HardeningFramework()
    
    if args.list:
        print("Available modules:")
        for module in framework.modules:
            print(f"  - {module}")
        return
    
    success = framework.run(args.module)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
