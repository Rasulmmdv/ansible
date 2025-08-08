#!/bin/bash

# Enhanced CPU Load Monitoring and Stress Testing Script
# Version: 2.1
# Author: Enhanced version of original script

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script modes
readonly MODE_NORMAL="normal"
readonly MODE_TEST="test"
readonly MODE_DRY_RUN="dry-run"

# Configuration
readonly CONFIG_FILE="${CONFIG_FILE:-./cpu_load.conf}"
readonly LOG_FILE="${LOG_FILE:-./logs/cpu_stress.log}"
readonly DATA_FILE="${DATA_FILE:-./data/cpu_utilization_data.txt}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration values
readonly DEFAULT_UTILIZATION_THRESHOLD=20
readonly DEFAULT_MAX_CPU_UTILIZATION=60
readonly DEFAULT_DURATION_MINUTES=60
readonly DEFAULT_LOG_RETENTION_DAYS=30
readonly DEFAULT_DATA_RETENTION_DAYS=7
readonly REQUIRED_PACKAGES="stress-ng"

# Test mode configuration (shorter duration for testing)
readonly TEST_DURATION_MINUTES=2
readonly TEST_MAX_CPU_UTILIZATION=30

# Parse command line arguments
parse_arguments() {
    local mode="$MODE_NORMAL"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --test|-t)
                mode="$MODE_TEST"
                shift
                ;;
            --dry-run|-d)
                mode="$MODE_DRY_RUN"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "$mode"
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

CPU Load Monitoring and Stress Testing Script

OPTIONS:
    --test, -t        Run in test mode (shorter stress test)
    --dry-run, -d     Run in dry-run mode (simulate without actual stress)
    --help, -h        Show this help message

EXAMPLES:
    $0                 # Normal operation
    $0 --test         # Test mode with 2-minute stress test
    $0 --dry-run      # Dry run mode (no actual stress)

EOF
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        echo "Configuration file not found. Using defaults."
    fi
    
    # Set defaults if not provided
    UTILIZATION_THRESHOLD="${UTILIZATION_THRESHOLD:-$DEFAULT_UTILIZATION_THRESHOLD}"
    MAX_CPU_UTILIZATION="${MAX_CPU_UTILIZATION:-$DEFAULT_MAX_CPU_UTILIZATION}"
    DURATION_MINUTES="${DURATION_MINUTES:-$DEFAULT_DURATION_MINUTES}"
    LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-$DEFAULT_LOG_RETENTION_DAYS}"
    DATA_RETENTION_DAYS="${DATA_RETENTION_DAYS:-$DEFAULT_DATA_RETENTION_DAYS}"
}

# Setup logging
setup_logging() {
    local log_dir
    log_dir="$(dirname "$LOG_FILE")"
    
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
    fi
    
    # Create data directory if it doesn't exist
    local data_dir
    data_dir="$(dirname "$DATA_FILE")"
    if [[ ! -d "$data_dir" ]]; then
        mkdir -p "$data_dir"
    fi
}

# Logging function with levels
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists before writing
    local log_dir
    log_dir="$(dirname "$LOG_FILE")"
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" 2>/dev/null || true
    fi
    
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$timestamp] [$level] $message"
}

# Error handling
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Check if running as root (for package installation)
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        log "WARN" "Script is running as root. This is not recommended for security reasons."
    fi
}

# Function to check and install packages if they are not installed
install_packages() {
    log "INFO" "Checking required packages..."
    
    for package in $REQUIRED_PACKAGES; do
        if ! dpkg -l | grep -q " $package "; then
            log "INFO" "Package '$package' is not installed. Installing..."
            if ! sudo apt-get install -y "$package"; then
                error_exit "Failed to install package: $package"
            fi
        else
            log "DEBUG" "Package '$package' is already installed."
        fi
    done
}

# More efficient CPU utilization check
check_utilization() {
    local cpu_utilization
    local timestamp
    
    # Use /proc/loadavg for more efficient CPU monitoring
    cpu_utilization=$(awk '{print int($1 * 100 / '$(nproc)')}' /proc/loadavg 2>/dev/null || echo "0")
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$cpu_utilization $timestamp" >> "$DATA_FILE"
    
    log "INFO" "Current CPU Utilization: ${cpu_utilization}%"
    echo "$cpu_utilization"
}

# Calculate 95th percentile of CPU utilization with error handling
calculate_95th_percentile() {
    if [[ ! -f "$DATA_FILE" ]]; then
        log "WARN" "Data file not found. Cannot calculate percentile."
        return 1
    fi
    
    local timestamp_24_hours_ago
    timestamp_24_hours_ago=$(date -d "24 hours ago" '+%Y-%m-%d %H:%M:%S')
    
    # Filter and sort CPU utilization samples within the last 24 hours
    local cpu_utilizations
    mapfile -t cpu_utilizations < <(awk -v start="$timestamp_24_hours_ago" '$2 >= start {print $1}' "$DATA_FILE" | sort -n)
    
    local total_samples=${#cpu_utilizations[@]}
    
    if [[ $total_samples -eq 0 ]]; then
        log "WARN" "No data available for the last 24 hours."
        return 1
    fi
    
    local index_95_percent=$((total_samples * 95 / 100))
    local utilization_95_percent=${cpu_utilizations[$index_95_percent]}
    
    log "INFO" "95th Percentile CPU Utilization: ${utilization_95_percent}%"
    log "INFO" "Threshold: ${UTILIZATION_THRESHOLD}%"
    
    # Use awk for floating-point comparison
    if awk -v u="$utilization_95_percent" -v t="$UTILIZATION_THRESHOLD" 'BEGIN {exit u < t ? 0 : 1}'; then
        return 0
    else
        return 1
    fi
}

# Enhanced stress CPU function
stress_cpu() {
    local mode="${1:-$MODE_NORMAL}"
    local stress_seconds
    local num_cores
    local cpu_load
    
    # Adjust parameters based on mode
    if [[ "$mode" == "$MODE_TEST" ]]; then
        stress_seconds=$((TEST_DURATION_MINUTES * 60))
        cpu_load="$TEST_MAX_CPU_UTILIZATION"
        log "INFO" "TEST MODE: Starting stress test with ${cpu_load}% load for ${TEST_DURATION_MINUTES} minutes"
    else
        stress_seconds=$((DURATION_MINUTES * 60))
        cpu_load="$MAX_CPU_UTILIZATION"
        log "INFO" "Starting stress test with ${cpu_load}% load for ${DURATION_MINUTES} minutes"
    fi
    
    num_cores=$(nproc)
    log "INFO" "Using $num_cores CPU cores"
    
    # Run the stress-ng command to distribute load across all cores
    if stress-ng --cpu "$num_cores" --cpu-load "$cpu_load" --timeout "${stress_seconds}s" >> "$LOG_FILE" 2>&1; then
        log "INFO" "Stress test completed successfully"
    else
        log "ERROR" "Stress test failed"
        return 1
    fi
}

# Dry run stress test function
dry_run_stress_cpu() {
    local mode="${1:-$MODE_NORMAL}"
    local stress_seconds
    local cpu_load
    
    # Calculate what would be used
    if [[ "$mode" == "$MODE_TEST" ]]; then
        stress_seconds=$((TEST_DURATION_MINUTES * 60))
        cpu_load="$TEST_MAX_CPU_UTILIZATION"
        log "INFO" "DRY RUN - TEST MODE: Would run stress test with ${cpu_load}% load for ${TEST_DURATION_MINUTES} minutes"
    else
        stress_seconds=$((DURATION_MINUTES * 60))
        cpu_load="$MAX_CPU_UTILIZATION"
        log "INFO" "DRY RUN: Would run stress test with ${cpu_load}% load for ${DURATION_MINUTES} minutes"
    fi
    
    local num_cores
    num_cores=$(nproc)
    log "INFO" "DRY RUN: Would use $num_cores CPU cores"
    log "INFO" "DRY RUN: Stress test simulation completed"
}

# Cleanup old data and logs
cleanup_old_data() {
    log "INFO" "Cleaning up old data and logs..."
    
    # Clean up old log entries
    if [[ -f "$LOG_FILE" ]]; then
        local cutoff_date
        cutoff_date=$(date -d "$LOG_RETENTION_DAYS days ago" '+%Y-%m-%d')
        sed -i "/^\[$cutoff_date/d" "$LOG_FILE" 2>/dev/null || true
    fi
    
    # Clean up old data entries
    if [[ -f "$DATA_FILE" ]]; then
        local cutoff_date
        cutoff_date=$(date -d "$DATA_RETENTION_DAYS days ago" '+%Y-%m-%d')
        sed -i "/^[0-9]* $cutoff_date/d" "$DATA_FILE" 2>/dev/null || true
    fi
}

# Health check function
health_check() {
    log "INFO" "Performing health check..."
    
    # Check if required commands are available
    if ! command -v stress-ng &> /dev/null; then
        log "WARN" "stress-ng is not available in PATH, will attempt to install"
        # Don't exit, let the install_packages function handle it
    else
        log "INFO" "stress-ng is available"
    fi
    
    # Check disk space
    local available_space
    available_space=$(df . | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 1048576 ]]; then  # Less than 1GB
        log "WARN" "Low disk space available: ${available_space}KB"
    fi
    
    log "INFO" "Health check passed"
}

# Main execution function
main() {
    # Parse command line arguments
    local script_mode
    script_mode=$(parse_arguments "$@")
    
    # Load configuration first
    load_config
    
    # Setup logging before any log calls
    setup_logging
    
    # Now we can safely log
    log "INFO" "Starting CPU load monitoring script (Mode: $script_mode)"
    
    # Check permissions
    check_permissions
    
    # Health check
    health_check
    
    # Check and install required packages
    install_packages
    
    # Cleanup old data
    cleanup_old_data
    
    # Check CPU utilization
    check_utilization
    
    # Handle different modes
    if [[ "$script_mode" == "$MODE_TEST" ]]; then
        log "INFO" "TEST MODE: Running stress test regardless of time or threshold"
        if calculate_95th_percentile; then
            log "INFO" "CPU utilization below threshold. Starting test stress test."
            stress_cpu "$script_mode"
        else
            log "INFO" "CPU utilization above threshold, but running test anyway."
            stress_cpu "$script_mode"
        fi
    elif [[ "$script_mode" == "$MODE_DRY_RUN" ]]; then
        log "INFO" "DRY RUN MODE: Simulating stress test execution"
        if calculate_95th_percentile; then
            log "INFO" "CPU utilization below threshold. Would start stress test."
            dry_run_stress_cpu "$script_mode"
        else
            log "INFO" "CPU utilization above threshold. Would skip stress test."
        fi
    else
        # Normal mode - Execute stress test once a day if 95th percentile CPU utilization is below the threshold
        if [[ "$(date +%H)" == "00" ]]; then
            log "INFO" "Daily stress test check initiated"
            if calculate_95th_percentile; then
                log "INFO" "CPU utilization below threshold. Starting stress test."
                stress_cpu "$script_mode"
            else
                log "INFO" "CPU utilization above threshold. Skipping stress test."
            fi
        else
            log "DEBUG" "Not midnight yet. Stress test will run at 00:00 if CPU utilization is below threshold."
        fi
    fi
    
    log "INFO" "CPU load monitoring script completed"
}

# Trap to handle script interruption
trap 'log "WARN" "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@" 