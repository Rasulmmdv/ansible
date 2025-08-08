#!/bin/bash
# Prometheus and Loki Retention Cleanup Script
# This script provides manual cleanup and monitoring of retention policies

set -e

# Configuration
PROMETHEUS_URL="http://localhost:9090"
LOKI_URL="http://localhost:3100"
MONITORING_DATA_DIR="/opt/monitoring"
RETENTION_DAYS=30
LOG_FILE="/var/log/monitoring-cleanup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if services are running
check_services() {
    echo -e "${BLUE}=== Checking Service Status ===${NC}"
    
    # Check Prometheus
    if curl -s "${PROMETHEUS_URL}/api/v1/query?query=up" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Prometheus is running${NC}"
        PROMETHEUS_RUNNING=true
    else
        echo -e "${RED}✗ Prometheus is not accessible${NC}"
        PROMETHEUS_RUNNING=false
    fi
    
    # Check Loki
    if curl -s "${LOKI_URL}/ready" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Loki is running${NC}"
        LOKI_RUNNING=true
    else
        echo -e "${RED}✗ Loki is not accessible${NC}"
        LOKI_RUNNING=false
    fi
}

# Check Prometheus retention status
check_prometheus_retention() {
    echo -e "\n${BLUE}=== Prometheus Retention Status ===${NC}"
    
    if [ "$PROMETHEUS_RUNNING" = true ]; then
        # Get TSDB stats
        local tsdb_stats=$(curl -s "${PROMETHEUS_URL}/api/v1/status/tsdb" | jq -r '.data')
        
        if [ "$tsdb_stats" != "null" ]; then
            echo "TSDB Head Series: $(echo $tsdb_stats | jq -r '.headStats.numSeries')"
            echo "TSDB Head Samples: $(echo $tsdb_stats | jq -r '.headStats.numSamples')"
            echo "TSDB Symbol Table Size: $(echo $tsdb_stats | jq -r '.seriesCountByMetricName | length')"
        fi
        
        # Get configuration
        local config=$(curl -s "${PROMETHEUS_URL}/api/v1/status/config" | jq -r '.data.yaml')
        if [ "$config" != "null" ]; then
            echo "Storage retention configured in prometheus.yml"
        fi
        
        # Get runtime info
        local runtime_info=$(curl -s "${PROMETHEUS_URL}/api/v1/status/runtimeinfo" | jq -r '.data')
        if [ "$runtime_info" != "null" ]; then
            echo "Storage Retention: $(echo $runtime_info | jq -r '.storageRetention')"
            echo "Corruption Count: $(echo $runtime_info | jq -r '.corruptionCount')"
        fi
    else
        echo -e "${YELLOW}Prometheus not running, skipping retention check${NC}"
    fi
}

# Check Loki retention status
check_loki_retention() {
    echo -e "\n${BLUE}=== Loki Retention Status ===${NC}"
    
    if [ "$LOKI_RUNNING" = true ]; then
        # Get Loki config
        local config=$(curl -s "${LOKI_URL}/config" 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "Loki configuration retrieved successfully"
            # Check if retention is enabled
            if echo "$config" | grep -q "retention_enabled.*true"; then
                echo -e "${GREEN}✓ Retention is enabled${NC}"
            else
                echo -e "${YELLOW}⚠ Retention may not be enabled${NC}"
            fi
        else
            echo -e "${YELLOW}Unable to retrieve Loki configuration${NC}"
        fi
        
        # Get Loki metrics
        local metrics=$(curl -s "${LOKI_URL}/metrics" 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "Loki metrics retrieved successfully"
            # Check compactor metrics
            if echo "$metrics" | grep -q "loki_compactor_runs_started_total"; then
                echo -e "${GREEN}✓ Compactor is running${NC}"
            else
                echo -e "${YELLOW}⚠ Compactor may not be running${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}Loki not running, skipping retention check${NC}"
    fi
}

# Check disk usage
check_disk_usage() {
    echo -e "\n${BLUE}=== Disk Usage Status ===${NC}"
    
    if [ -d "$MONITORING_DATA_DIR" ]; then
        local disk_usage=$(df -h "$MONITORING_DATA_DIR" | tail -1)
        echo "Monitoring data directory: $MONITORING_DATA_DIR"
        echo "Disk usage: $disk_usage"
        
        # Check individual component sizes
        echo -e "\n${BLUE}Component Sizes:${NC}"
        if [ -d "${MONITORING_DATA_DIR}/prometheus" ]; then
            local prom_size=$(du -sh "${MONITORING_DATA_DIR}/prometheus" | cut -f1)
            echo "Prometheus data: $prom_size"
        fi
        
        if [ -d "${MONITORING_DATA_DIR}/loki" ]; then
            local loki_size=$(du -sh "${MONITORING_DATA_DIR}/loki" | cut -f1)
            echo "Loki data: $loki_size"
        fi
        
        if [ -d "${MONITORING_DATA_DIR}/grafana" ]; then
            local grafana_size=$(du -sh "${MONITORING_DATA_DIR}/grafana" | cut -f1)
            echo "Grafana data: $grafana_size"
        fi
    else
        echo -e "${RED}✗ Monitoring data directory not found: $MONITORING_DATA_DIR${NC}"
    fi
}

# Force cleanup old data
force_cleanup() {
    echo -e "\n${BLUE}=== Force Cleanup (${RETENTION_DAYS} days) ===${NC}"
    
    read -p "This will permanently delete data older than $RETENTION_DAYS days. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cleanup cancelled"
        return 0
    fi
    
    log "Starting force cleanup of monitoring data older than $RETENTION_DAYS days"
    
    # Calculate cutoff date
    local cutoff_date=$(date -d "$RETENTION_DAYS days ago" +%Y-%m-%d)
    echo "Cutoff date: $cutoff_date"
    
    # Cleanup Prometheus data
    if [ -d "${MONITORING_DATA_DIR}/prometheus/data" ]; then
        echo "Cleaning up Prometheus data..."
        find "${MONITORING_DATA_DIR}/prometheus/data" -type d -name "*" -mtime +$RETENTION_DAYS -exec rm -rf {} + 2>/dev/null || true
        log "Prometheus data cleanup completed"
    fi
    
    # Cleanup Loki data
    if [ -d "${MONITORING_DATA_DIR}/loki/chunks" ]; then
        echo "Cleaning up Loki chunks..."
        find "${MONITORING_DATA_DIR}/loki/chunks" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
        log "Loki chunks cleanup completed"
    fi
    
    if [ -d "${MONITORING_DATA_DIR}/loki/tsdb-index" ]; then
        echo "Cleaning up Loki index..."
        find "${MONITORING_DATA_DIR}/loki/tsdb-index" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
        log "Loki index cleanup completed"
    fi
    
    # Cleanup WAL files
    if [ -d "${MONITORING_DATA_DIR}/prometheus/data/wal" ]; then
        echo "Cleaning up Prometheus WAL..."
        find "${MONITORING_DATA_DIR}/prometheus/data/wal" -type f -mtime +1 -delete 2>/dev/null || true
        log "Prometheus WAL cleanup completed"
    fi
    
    if [ -d "${MONITORING_DATA_DIR}/loki/wal" ]; then
        echo "Cleaning up Loki WAL..."
        find "${MONITORING_DATA_DIR}/loki/wal" -type f -mtime +1 -delete 2>/dev/null || true
        log "Loki WAL cleanup completed"
    fi
    
    echo -e "${GREEN}✓ Force cleanup completed${NC}"
}

# Compact Prometheus data
compact_prometheus() {
    echo -e "\n${BLUE}=== Prometheus Compaction ===${NC}"
    
    if [ "$PROMETHEUS_RUNNING" = true ]; then
        echo "Triggering Prometheus compaction..."
        local response=$(curl -s -X POST "${PROMETHEUS_URL}/api/v1/admin/tsdb/snapshot" 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Prometheus compaction triggered${NC}"
            log "Prometheus compaction triggered manually"
        else
            echo -e "${RED}✗ Failed to trigger Prometheus compaction${NC}"
        fi
    else
        echo -e "${YELLOW}Prometheus not running, skipping compaction${NC}"
    fi
}

# Show help
show_help() {
    echo "Prometheus and Loki Retention Cleanup Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -c, --check       Check retention status and disk usage"
    echo "  -f, --force       Force cleanup of old data"
    echo "  -p, --compact     Trigger Prometheus compaction"
    echo "  -r, --retention   Set retention days (default: 30)"
    echo "  -h, --help        Show this help message"
    echo
    echo "Examples:"
    echo "  $0 -c              # Check status"
    echo "  $0 -f              # Force cleanup (interactive)"
    echo "  $0 -r 15 -f        # Force cleanup with 15 days retention"
    echo "  $0 -p              # Trigger compaction"
}

# Main execution
main() {
    case "${1:-}" in
        -c|--check)
            check_services
            check_prometheus_retention
            check_loki_retention
            check_disk_usage
            ;;
        -f|--force)
            check_services
            force_cleanup
            ;;
        -p|--compact)
            check_services
            compact_prometheus
            ;;
        -r|--retention)
            if [ -n "$2" ]; then
                RETENTION_DAYS="$2"
                shift 2
                main "$@"
            else
                echo "Error: --retention requires a number"
                exit 1
            fi
            ;;
        -h|--help)
            show_help
            ;;
        "")
            check_services
            check_prometheus_retention
            check_loki_retention
            check_disk_usage
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Create log file if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Run main function
main "$@"