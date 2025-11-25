# Linux System Hardening Framework

A comprehensive, production-ready Linux hardening tool implementing CIS-style security controls across 9 major domains.

## 🔒 Features

- **9 Security Modules**: Comprehensive coverage of system hardening
- **200+ Security Rules**: Based on industry best practices and CIS benchmarks
- **YAML-Driven Configuration**: Easy to read, modify, and extend
- **Idempotent Operations**: Safe to run multiple times
- **Automatic Rollback**: Failed rules trigger automatic rollback
- **Detailed Logging**: Every action logged with timestamps
- **Multi-Distribution Support**: Ubuntu 20.04+, CentOS 7+, RHEL 8+

## 📋 Modules

1. **Filesystem Security** - Kernel modules, partition hardening, mount options
2. **Package Management & Bootloader** - GRUB protection, process hardening, banners
3. **Services** - Disable unnecessary services, time sync, cron security
4. **Network** - Kernel parameters, protocol restrictions, network hardening
5. **Host-Based Firewall** - UFW/firewalld configuration
6. **Access Control** - SSH hardening, sudo configuration, PAM settings
7. **User Accounts** - Password policies, account validation, environment security
8. **Logging & Auditing** - journald, rsyslog, auditd, AIDE integrity checking
9. **System Maintenance** - File permissions, SUID/SGID, orphaned files

## 🚀 Quick Start

### Installation

```bash
# Download and run the deployment script
sudo bash deployment.sh

# Or manually:
cd /opt
git clone <your-repo> linux-hardening
cd linux-hardening
```

### Directory Structure

```
/opt/linux-hardening/
├── harden.py                 # Main Python controller
├── quickstart.sh            # Interactive hardening script
├── rules/                   # YAML rule definitions
│   ├── 01_filesystem.yaml
│   ├── 02_package_management.yaml
│   ├── 03_services.yaml
│   ├── 04_network.yaml
│   ├── 05_firewall.yaml
│   ├── 06_access_control.yaml
│   ├── 07_user_accounts.yaml
│   ├── 08_logging_auditing.yaml
│   └── 09_system_maintenance.yaml
├── scripts/                 # Bash executors
│   ├── executor.sh         # Universal executor
│   ├── 01_filesystem.sh    # Module symlinks
│   └── ...
├── logs/                    # Execution logs
└── reports/                 # JSON reports
```

## 💻 Usage

### Run All Modules

```bash
cd /opt/linux-hardening
sudo python3 harden.py
```

### Run Specific Module

```bash
# Run only SSH hardening
sudo python3 harden.py -m 06_access_control

# Run only network hardening
sudo python3 harden.py -m 04_network
```

### List Available Modules

```bash
python3 harden.py -l
```

### Interactive Mode

```bash
sudo ./quickstart.sh
```

### Test Single Module

```bash
sudo bash scripts/01_filesystem.sh rules/01_filesystem.yaml
```

## 📊 Sample Output

### Module Execution

```
================================================================================
Starting Hardening Module: Filesystem Security (01_filesystem)
================================================================================
[INFO] Rules file: /opt/linux-hardening/rules/01_filesystem.yaml
[INFO] Total rules to process: 20

================================================================================
Rule: FS-001
================================================================================
[INFO] Description: Ensure cramfs kernel module is not available
[INFO] Severity: medium
[INFO] Notes: cramfs is a compressed read-only filesystem rarely needed
[INFO] Applying configuration...
[SUCCESS] Configuration applied
[INFO] Verifying configuration...
[SUCCESS] ✓ Rule FS-001 PASSED

================================================================================
Rule: FS-010
================================================================================
[INFO] Description: Ensure /tmp is a separate partition
[INFO] Severity: high
[INFO] Notes: Separating /tmp prevents resource exhaustion
[INFO] Applying configuration...
[SUCCESS] Configuration applied
[INFO] Verifying configuration...
[SUCCESS] ✓ Rule FS-010 PASSED

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
```

### Final Summary

```
================================================================================
Linux System Hardening Framework v1.0.0
================================================================================
OS: Ubuntu 22.04
Start Time: 2024-11-25 10:30:15
End Time: 2024-11-25 10:45:32

Module Results:
  01_filesystem: SUCCESS
  02_package_management: SUCCESS
  03_services: SUCCESS
  04_network: SUCCESS
  05_firewall: SUCCESS
  06_access_control: SUCCESS
  07_user_accounts: SUCCESS
  08_logging_auditing: SUCCESS
  09_system_maintenance: SUCCESS

Hardening Complete: 9 succeeded, 0 failed

Detailed report saved to: /opt/linux-hardening/reports/hardening_report_20241125_104532.json
```

## 🔧 Customization

### Modify Rules

Edit any YAML file in `rules/` directory:

```yaml
rules:
  - id: CUSTOM-001
    category: "Custom Category"
    description: "My custom security rule"
    severity: "high"
    apply: |
      # Your bash commands here
      echo "Applying custom rule"
    verify: |
      # Verification commands
      # Must output "PASS", "FAIL", or "SKIP"
      [ -f /etc/myconfig ] && echo "PASS" || echo "FAIL"
    rollback: |
      # Rollback commands
      rm -f /etc/myconfig
    notes: "Explanation of what this rule does"
```

### Add New Module

1. Create `rules/10_custom_module.yaml`
2. Define rules following the YAML structure
3. Create symlink: `ln -s executor.sh scripts/10_custom_module.sh`
4. Add to `modules` list in `harden.py`

## ⚠️ Important Notes

### Before Running

- **BACKUP YOUR SYSTEM** - Always have a full backup
- **Test in Non-Production** - Test all rules in a dev environment first
- **Physical/Console Access** - Ensure you have console access in case SSH is affected
- **Review Rules** - Read each rule and understand its impact
- **Review Firewall Rules** - Especially critical for remote systems

### Critical Rules

Some rules are marked as **CRITICAL** severity:

- **FW-006**: Ensure SSH is allowed in firewall (prevents lockout)
- **AC-002**: SSH root login disabled (ensure you have sudo access)
- **SYS-015**: Shadow password validation
- **PKG-001**: Bootloader password protection

### Testing SSH After Hardening

**CRITICAL**: After running access control module, test SSH in a **NEW** terminal:

```bash
# In a new terminal window
ssh user@your-server

# If connection fails, you still have your original session
# to investigate and fix
```

### Rules That Require Reboot

- **LOG-013**: Audit for early boot processes
- **PKG-001**: Bootloader password changes
- Kernel parameter changes will persist but some take effect immediately

## 📁 Log Files

All operations are logged:

```bash
# View latest hardening log
tail -f /opt/linux-hardening/logs/hardening_*.log

# View specific module output
grep "FS-" /opt/linux-hardening/logs/hardening_*.log

# View only failures
grep "FAIL" /opt/linux-hardening/logs/hardening_*.log
```

## 📄 Reports

JSON reports generated after each run:

```bash
# View latest report
cat /opt/linux-hardening/reports/hardening_report_*.json | jq '.'

# Count successful modules
cat report.json | jq '.modules | to_entries | map(select(.value.status=="success")) | length'
```

## 🔄 Rollback

### Automatic Rollback

Failed rules automatically trigger rollback of that specific rule.

### Manual Rollback

```bash
# Restore from backup (created by SYS-022)
cd /root
tar -xzf hardening-backup-*.tar.gz
# Manually restore files as needed
```

### Disable Specific Rules

Comment out rules in YAML files:

```yaml
# rules:
#   - id: FS-001
#     ...rule definition...
```

## 🎯 Common Use Cases

### Minimal Hardening (Development)

```bash
# Run only essential modules
python3 harden.py -m 06_access_control  # SSH hardening
python3 harden.py -m 05_firewall        # Firewall
python3 harden.py -m 07_user_accounts   # Password policies
```

### Full Server Hardening (Production)

```bash
# Run all modules
python3 harden.py
```

### Audit-Only Mode

Modify verify commands to not apply changes:

```yaml
apply: |
  echo "Would apply: <command>"
```

## 🐛 Troubleshooting

### yq Not Found

```bash
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
chmod +x /usr/bin/yq
```

### Permission Denied

```bash
# Must run as root
sudo python3 harden.py
```

### SSH Lockout

If locked out after hardening:

1. Access via console/physical access
2. Check `/etc/ssh/sshd_config`
3. Check firewall: `ufw status` or `firewall-cmd --list-all`
4. Restore from backup in `/root/hardening-backup-*.tar.gz`

### Module Fails

```bash
# Run module individually to see detailed output
sudo bash scripts/06_access_control.sh rules/06_access_control.yaml
```

## 🤝 Contributing

To add new rules:

1. Follow existing YAML structure
2. Test thoroughly
3. Document in `notes` field
4. Set appropriate severity level
5. Implement proper rollback

## 📜 License

This framework is provided as-is for security hardening purposes.

## ⚡ Performance

- Average execution time: 15-20 minutes for all modules
- Single module: 1-3 minutes
- No system restart required (except for kernel parameters)

## 🔐 Security Notice

This tool modifies critical system configurations. Always:

- Review rules before applying
- Test in non-production first
- Have backup and recovery plan
- Maintain console access
- Document any customizations

## 📞 Support

For issues or questions:
1. Check logs in `logs/` directory
2. Review the specific YAML rule
3. Test rule individually
4. Check rollback procedures

---

**Version**: 1.0.0  
**Last Updated**: November 2024  
**Tested On**: Ubuntu 20.04/22.04, CentOS 7/8, RHEL 8
