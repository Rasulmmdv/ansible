# CPU Load Monitoring and Stress Testing Script

## Overview
This script monitors CPU utilization and runs stress tests when the system is underutilized. It's designed to help maintain optimal system performance by ensuring the CPU gets adequate exercise.

## Files
- `cpu_load.sh` - Original script
- `cpu_load_enhanced.sh` - Enhanced version with improvements
- `cpu_load.conf` - Configuration file for environment-specific settings
- `README.md` - This documentation

## Key Improvements in Enhanced Version

### 1. **Error Handling & Robustness**
- Added `set -euo pipefail` for strict error handling
- Comprehensive error checking and graceful failure handling
- Proper exit codes and error messages

### 2. **Configuration Management**
- External configuration file support
- Environment-specific settings (dev/test/prod)
- Default values with override capability
- Environment variable support

### 3. **Enhanced Logging**
- Structured logging with levels (INFO, WARN, ERROR, DEBUG)
- Automatic log directory creation
- Log rotation and cleanup
- Timestamped entries

### 4. **Performance Optimizations**
- More efficient CPU monitoring using `/proc/loadavg`
- Data cleanup to prevent file bloat
- Optimized data processing

### 5. **Security Improvements**
- Permission checking
- Input validation
- Safe file operations
- Warning when running as root

### 6. **Maintenance Features**
- Automatic cleanup of old logs and data
- Health checks
- Disk space monitoring
- Package dependency management

### 7. **Code Quality**
- Better function organization
- Consistent naming conventions
- Comprehensive comments
- Modular design

## Usage

### Basic Usage
```bash
# Run the enhanced script
./cpu_load_enhanced.sh

# Run with custom configuration
CONFIG_FILE=./prod.conf ./cpu_load_enhanced.sh
```

### Configuration
Create a configuration file (e.g., `cpu_load.conf`):
```bash
# CPU utilization threshold (percentage)
UTILIZATION_THRESHOLD=15

# Maximum CPU utilization during stress test
MAX_CPU_UTILIZATION=50

# Duration of stress test (minutes)
DURATION_MINUTES=30

# Log retention period (days)
LOG_RETENTION_DAYS=7

# Data retention period (days)
DATA_RETENTION_DAYS=3
```

### Environment Variables
You can override configuration using environment variables:
```bash
export UTILIZATION_THRESHOLD=10
export MAX_CPU_UTILIZATION=30
./cpu_load_enhanced.sh
```

## Directory Structure
```
.
├── cpu_load_enhanced.sh    # Enhanced script
├── cpu_load.conf          # Configuration file
├── logs/                  # Log directory (auto-created)
│   └── cpu_stress.log    # Log file
└── data/                  # Data directory (auto-created)
    └── cpu_utilization_data.txt  # CPU utilization data
```

## Scheduling
To run the script periodically, add to crontab:
```bash
# Run every hour
0 * * * * /path/to/cpu_load_enhanced.sh

# Run daily at midnight
0 0 * * * /path/to/cpu_load_enhanced.sh
```

## Monitoring
The script provides comprehensive logging:
- Current CPU utilization
- 95th percentile calculations
- Stress test execution status
- Error conditions and warnings
- Health check results

## Troubleshooting

### Common Issues
1. **Permission denied**: Ensure the script is executable (`chmod +x cpu_load_enhanced.sh`)
2. **Package installation fails**: Check sudo privileges and internet connectivity
3. **Low disk space**: The script will warn when disk space is low
4. **Configuration not found**: Script will use defaults if config file is missing

### Log Analysis
Check the log file for detailed information:
```bash
tail -f logs/cpu_stress.log
```

## Security Considerations
- The script uses `sudo` for package installation
- Avoid running as root for security reasons
- Log files may contain sensitive system information
- Ensure proper file permissions on configuration files

## Future Enhancements
- Web dashboard for monitoring
- Email/SMS notifications
- Integration with monitoring systems (Prometheus, Grafana)
- Docker containerization
- API endpoints for remote monitoring 