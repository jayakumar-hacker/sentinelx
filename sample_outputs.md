# Sample Execution Outputs

## Complete Framework Execution

### Initial Execution

```bash
root@server:~# cd /opt/linux-hardening
root@server:/opt/linux-hardening# python3 harden.py

================================================================================
Linux System Hardening Framework
Version 1.0.0
================================================================================
2024-11-25 10:30:15,123 - INFO - Checking prerequisites...
2024-11-25 10:30:15,234 - INFO - Prerequisites check passed
2024-11-25 10:30:15,235 - INFO - Detected OS: Ubuntu 22.04.3 LTS

================================================================================
Executing module: 01_filesystem
================================================================================
2024-11-25 10:30:15,456 - INFO - Starting Hardening Module: Filesystem Security (01_filesystem)
2024-11-25 10:30:15,457 - INFO - Rules file: /opt/linux-hardening/rules/01_filesystem.yaml
2024-11-25 10:30:15,458 - INFO - Timestamp: 2024-11-25 10:30:15
2024-11-25 10:30:15,459 - INFO - Total rules to process: 20

================================================================================
Rule: FS-001
================================================================================
[INFO] Description: Ensure cramfs kernel module is not available
[INFO] Severity: medium
[INFO] Notes: cramfs is a compressed read-only filesystem rarely needed on modern systems
[INFO] Applying configuration...
[SUCCESS] Configuration applied
[INFO] Verifying configuration...
[SUCCESS] ✓ Rule FS-001 PASSED

================================================================================
Rule: FS-002
================================================================================
[INFO] Description: Ensure freevxfs kernel module is not available
[INFO] Severity: medium
[INFO] Notes: freevxfs is Veritas filesystem, not commonly used
[INFO] Applying configuration...
[SUCCESS] Configuration applied
[INFO] Verifying configuration...
[SUCCESS] ✓ Rule FS-002 PASSED

[... 18 more rules ...]

================================================================================
Module Execution Summary
================================================================================
[INFO] Module: Filesystem Security (01_filesystem)
[INFO] Total Rules: 20
[SUCCESS] Passed: 18
[ERROR] Failed: 0
[WARNING] Skipped: 2
[INFO] Success Rate: 90%
[SUCCESS] Module completed successfully!

================================================================================
Executing module: 02_package_management
================================================================================
[INFO] Starting Hardening Module: Package Management & Bootloader Security
[INFO] Total rules to process: 12

[... execution continues for all 9 modules ...]

================================================================================
HARDENING SUMMARY
================================================================================
[INFO] Module: Filesystem Security (01_filesystem)
[SUCCESS] Passed: 18, Failed: 0, Skipped: 2

[INFO] Module: Package Management & Bootloader Security (02_package_management)
[SUCCESS] Passed: 11, Failed: 0, Skipped: 1

[INFO] Module: Services Security (03_services)
[SUCCESS] Passed: 22, Failed: 1, Skipped: 2

[INFO] Module: Network Security (04_network)
[SUCCESS] Passed: 18, Failed: 0, Skipped: 0

[INFO] Module: Host-Based Firewall (05_firewall)
[SUCCESS] Passed: 12, Failed: 0, Skipped: 0

[INFO] Module: Access Control Security (06_access_control)
[SUCCESS] Passed: 20, Failed: 0, Skipped: 2

[INFO] Module: User Accounts and Environment Security (07_user_accounts)
[SUCCESS] Passed: 19, Failed: 0, Skipped: 1

[INFO] Module: Logging and Auditing Security (08_logging_auditing)
[SUCCESS] Passed: 24, Failed: 0, Skipped: 1

[INFO] Module: System Maintenance Security (09_system_maintenance)
[SUCCESS] Passed: 21, Failed: 0, Skipped: 1

================================================================================
Hardening Complete: 9 succeeded, 0 failed
================================================================================
[INFO] Detailed report saved to: /opt/linux-hardening/reports/hardening_report_20241125_103045.json

Total Execution Time: 00:15:32
```

## Single Module Execution

### Running Only SSH Hardening

```bash
root@server:~# python3 harden.py -m 06_access_control

================================================================================
Executing module: 06_access_control
================================================================================
[INFO] Starting Hardening Module: Access Control Security (06_access_control)

================================================================================
Rule: AC-001
================================================================================
[INFO] Description: Ensure permissions on /etc/ssh/sshd_config are configured
[INFO] Severity: high
[INFO] Notes: Restrict SSH config to root only
[INFO] Applying configuration...
[SUCCESS] Configuration applied
[INFO] Verifying configuration...
[SUCCESS] ✓ Rule AC-001 PASSED

================================================================================
Rule: AC-002
================================================================================
[INFO] Description: Ensure SSH PermitRootLogin is disabled
[INFO] Severity: critical
[INFO] Notes: Prevent direct root login via SSH
[INFO] Applying configuration...
[SUCCESS] Configuration applied
[INFO] Verifying configuration...
[SUCCESS] ✓ Rule AC-002 PASSED

[... additional SSH rules ...]

================================================================================
Rule: AC-014
================================================================================
[INFO] Description: Ensure SSH strong ciphers are configured
[INFO] Severity: high
[INFO] Notes: Use only strong encryption ciphers
[INFO] Applying configuration...
[SUCCESS] Configuration applied
[INFO] Verifying configuration...
[SUCCESS] ✓ Rule AC-014 PASSED

================================================================================
Module Execution Summary
================================================================================
[INFO] Module: Access Control Security (06_access_control)
[INFO] Total Rules: 22
[SUCCESS] Passed: 20
[ERROR] Failed: 0
[WARNING] Skipped: 2
[INFO] Success Rate: 91%
[SUCCESS] Module completed successfully!

Execution Time: 00:02:15
```

## Failed Rule Example

### When a Rule Fails

```bash
================================================================================
Rule: FW-008
================================================================================
[INFO] Description: Enable ufw firewall
[INFO] Severity: critical
[INFO] Notes: CRITICAL: Activates firewall. Ensure SSH is allowed first.
[INFO] Applying configuration...
[WARNING] Configuration application had warnings
[INFO] Verifying configuration...
[ERROR] ✗ Rule FW-008 FAILED
[WARNING] Verification result: FAIL
[WARNING] Attempting rollback...
[INFO] Rollback completed

Note: UFW service is not installed on this system
Recommendation: Install ufw package first
```

## Skipped Rule Example

### When a Rule is Skipped

```bash
================================================================================
Rule: FS-017
================================================================================
[INFO] Description: Ensure nodev option set on /home partition
[INFO] Severity: medium
[INFO] Notes: Prevents device files in user home directories
[INFO] Applying configuration...
[SUCCESS] Configuration applied
[INFO] Verifying configuration...
[WARNING] ⊘ Rule FS-017 SKIPPED (not applicable)

Note: /home is not a separate partition on this system
```

## Interactive Mode

### Quick Start Script

```bash
root@server:~# cd /opt/linux-hardening
root@server:/opt/linux-hardening# ./quickstart.sh

===========================================
Linux Hardening Framework - Quick Start
===========================================

IMPORTANT: This will apply hardening to your system.
Make sure you have:
  1. A backup of your system
  2. Console/physical access (in case SSH is affected)
  3. Reviewed the rules in the rules/ directory

Continue? (yes/no): yes

Starting hardening process...

[... full execution output ...]

===========================================
Hardening Complete!
===========================================

CRITICAL: Test SSH access in a NEW terminal before logging out!
Check logs in: logs/
Check reports in: reports/

Summary:
  Total Rules Applied: 185
  Passed: 168
  Failed: 2
  Skipped: 15
  
  Failed Rules:
    - SVC-015: Web server not disabled (nginx running)
    - LOG-024: AIDE initialization timeout
    
Review /opt/linux-hardening/logs/hardening_20241125_103045.log for details
```

## JSON Report Example

### Generated Report Structure

```json
{
  "start_time": "2024-11-25T10:30:15.123456",
  "end_time": "2024-11-25T10:45:47.654321",
  "os_info": {
    "system": "Linux",
    "release": "5.15.0-91-generic",
    "distro": "ubuntu",
    "distro_version": "22.04",
    "machine": "x86_64"
  },
  "modules": {
    "01_filesystem": {
      "status": "success",
      "return_code": 0,
      "rules_total": 20,
      "rules_passed": 18,
      "rules_failed": 0,
      "rules_skipped": 2
    },
    "02_package_management": {
      "status": "success",
      "return_code": 0,
      "rules_total": 12,
      "rules_passed": 11,
      "rules_failed": 0,
      "rules_skipped": 1
    },
    "03_services": {
      "status": "success",
      "return_code": 0,
      "rules_total": 25,
      "rules_passed": 22,
      "rules_failed": 1,
      "rules_skipped": 2
    },
    "04_network": {
      "status": "success",
      "return_code": 0,
      "rules_total": 18,
      "rules_passed": 18,
      "rules_failed": 0,
      "rules_skipped": 0
    },
    "05_firewall": {
      "status": "success",
      "return_code": 0,
      "rules_total": 12,
      "rules_passed": 12,
      "rules_failed": 0,
      "rules_skipped": 0
    },
    "06_access_control": {
      "status": "success",
      "return_code": 0,
      "rules_total": 22,
      "rules_passed": 20,
      "rules_failed": 0,
      "rules_skipped": 2
    },
    "07_user_accounts": {
      "status": "success",
      "return_code": 0,
      "rules_total": 20,
      "rules_passed": 19,
      "rules_failed": 0,
      "rules_skipped": 1
    },
    "08_logging_auditing": {
      "status": "success",
      "return_code": 0,
      "rules_total": 25,
      "rules_passed": 24,
      "rules_failed": 0,
      "rules_skipped": 1
    },
    "09_system_maintenance": {
      "status": "success",
      "return_code": 0,
      "rules_total": 22,
      "rules_passed": 21,
      "rules_failed": 0,
      "rules_skipped": 1
    }
  },
  "summary": {
    "total_modules": 9,
    "successful_modules": 9,
    "failed_modules": 0,
    "total_rules": 176,
    "passed_rules": 165,
    "failed_rules": 1,
    "skipped_rules": 10,
    "overall_success_rate": "93.75%"
  }
}
```

## Log File Examples

### Detailed Log Output

```
2024-11-25 10:30:15,123 - INFO - ================================================================================
2024-11-25 10:30:15,124 - INFO - Linux System Hardening Framework
2024-11-25 10:30:15,125 - INFO - Version 1.0.0
2024-11-25 10:30:15,126 - INFO - ================================================================================
2024-11-25 10:30:15,234 - INFO - Checking prerequisites...
2024-11-25 10:30:15,235 - INFO - Prerequisites check passed
2024-11-25 10:30:15,456 - INFO - ================================================================================
2024-11-25 10:30:15,457 - INFO - Executing module: 01_filesystem
2024-11-25 10:30:15,458 - INFO - ================================================================================
2024-11-25 10:30:16,123 - INFO - Module 01_filesystem output:
2024-11-25 10:30:16,124 - INFO - [INFO] Rule FS-001: Ensure cramfs kernel module is not available
2024-11-25 10:30:16,234 - INFO - [SUCCESS] ✓ Rule FS-001 PASSED
2024-11-25 10:30:17,345 - INFO - [INFO] Rule FS-002: Ensure freevxfs kernel module is not available
2024-11-25 10:30:17,456 - INFO - [SUCCESS] ✓ Rule FS-002 PASSED
[... continues ...]
2024-11-25 10:45:47,123 - INFO - ================================================================================
2024-11-25 10:45:47,124 - INFO - HARDENING SUMMARY
2024-11-25 10:45:47,125 - INFO - ================================================================================
2024-11-25 10:45:47,126 - INFO - Hardening Complete: 9 succeeded, 0 failed
2024-11-25 10:45:47,127 - INFO - Detailed report saved to: /opt/linux-hardening/reports/hardening_report_20241125_103045.json
```

## Verification Commands

### Check Applied Rules

```bash
# Check if cramfs is disabled
root@server:~# modprobe -n -v cramfs
install /bin/true

# Check SSH configuration
root@server:~# sshd -T | grep permitrootlogin
permitrootlogin no

# Check firewall status
root@server:~# ufw status
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
22/tcp (v6)                ALLOW       Anywhere (v6)

# Check auditd rules
root@server:~# auditctl -l | grep sudoers
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d/ -p wa -k scope

# Check file permissions
root@server:~# stat /etc/shadow
  File: /etc/shadow
  Size: 1234          Blocks: 8          IO Block: 4096   regular file
Device: 801h/2049d    Inode: 262447      Links: 1
Access: (0640/-rw-r-----)  Uid: (    0/    root)   Gid: (   42/  shadow)
```

## Troubleshooting Output

### Common Issues

```bash
# Issue: yq not found
root@server:~# python3 harden.py
2024-11-25 10:30:15,123 - ERROR - Missing required tools: yq
2024-11-25 10:30:15,124 - INFO - Install yq: wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# Issue: Not running as root
user@server:~$ python3 harden.py
2024-11-25 10:30:15,123 - ERROR - This script must be run as root!

# Issue: Missing rules file
root@server:~# python3 harden.py -m 01_filesystem
2024-11-25 10:30:15,123 - ERROR - Rules file not found: /opt/linux-hardening/rules/01_filesystem.yaml
```

## Performance Metrics

### Execution Time by Module

```
Module                        Rules    Time      Status
================================================================
01_filesystem                 20       00:01:45  SUCCESS (90%)
02_package_management         12       00:02:15  SUCCESS (92%)
03_services                   25       00:02:30  SUCCESS (88%)
04_network                    18       00:01:20  SUCCESS (100%)
05_firewall                   12       00:01:10  SUCCESS (100%)
06_access_control             22       00:02:05  SUCCESS (91%)
07_user_accounts              20       00:01:55  SUCCESS (95%)
08_logging_auditing           25       00:03:20  SUCCESS (96%)
09_system_maintenance         22       00:02:12  SUCCESS (95%)
----------------------------------------------------------------
TOTAL                         176      00:18:32  SUCCESS (93%)
```

## System Resource Usage

```
CPU Usage:    5-15% (during execution)
Memory:       < 100MB
Disk I/O:     Minimal
Network:      None (except package updates if enabled)
```

---

These sample outputs demonstrate the framework's comprehensive logging, clear status reporting, and professional output formatting. The tool provides detailed feedback at every step, making it easy to understand what changes are being made and verify the results.
