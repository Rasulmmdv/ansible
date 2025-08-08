#!/bin/bash
# Test script for Prometheus and Loki retention policies

set -e

echo "=== Monitoring Stack Retention Test ==="
echo "Testing 30-day retention configuration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROMETHEUS_URL="http://localhost:9090"
LOKI_URL="http://localhost:3100"
EXPECTED_RETENTION="30d"
EXPECTED_RETENTION_HOURS="720h"

# Test functions
test_prometheus_retention() {
    echo -e "\n${BLUE}=== Testing Prometheus Retention Configuration ===${NC}"
    
    # Test runtime info
    echo -n "Testing Prometheus runtime retention... "
    local runtime_info=$(curl -s "${PROMETHEUS_URL}/api/v1/status/runtimeinfo" 2>/dev/null)
    if [ $? -eq 0 ]; then
        local retention=$(echo "$runtime_info" | jq -r '.data.storageRetention')
        if [ "$retention" = "$EXPECTED_RETENTION" ]; then
            echo -e "${GREEN}PASS${NC} (${retention})"
        else
            echo -e "${RED}FAIL${NC} (Expected: ${EXPECTED_RETENTION}, Got: ${retention})"
        fi
    else
        echo -e "${RED}FAIL${NC} (Cannot connect to Prometheus)"
    fi
    
    # Test TSDB status
    echo -n "Testing Prometheus TSDB status... "
    local tsdb_status=$(curl -s "${PROMETHEUS_URL}/api/v1/status/tsdb" 2>/dev/null)
    if [ $? -eq 0 ]; then
        local head_series=$(echo "$tsdb_status" | jq -r '.data.headStats.numSeries')
        if [ "$head_series" != "null" ] && [ "$head_series" -ge 0 ]; then
            echo -e "${GREEN}PASS${NC} (${head_series} series)"
        else
            echo -e "${YELLOW}WARN${NC} (TSDB data not available)"
        fi
    else
        echo -e "${RED}FAIL${NC} (Cannot retrieve TSDB status)"
    fi
    
    # Test configuration
    echo -n "Testing Prometheus config... "
    local config_response=$(curl -s "${PROMETHEUS_URL}/api/v1/status/config" 2>/dev/null)
    if [ $? -eq 0 ]; then
        if echo "$config_response" | jq -r '.data.yaml' | grep -q "storage.tsdb.retention.time"; then
            echo -e "${GREEN}PASS${NC} (Retention configured)"
        else
            echo -e "${YELLOW}WARN${NC} (Retention not found in config)"
        fi
    else
        echo -e "${RED}FAIL${NC} (Cannot retrieve config)"
    fi
}

test_loki_retention() {
    echo -e "\n${BLUE}=== Testing Loki Retention Configuration ===${NC}"
    
    # Test Loki ready
    echo -n "Testing Loki ready status... "
    if curl -s "${LOKI_URL}/ready" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC} (Loki not ready)"
        return 1
    fi
    
    # Test Loki config
    echo -n "Testing Loki retention config... "
    local config_response=$(curl -s "${LOKI_URL}/config" 2>/dev/null)
    if [ $? -eq 0 ]; then
        if echo "$config_response" | grep -q "retention_period.*${EXPECTED_RETENTION_HOURS}"; then
            echo -e "${GREEN}PASS${NC} (${EXPECTED_RETENTION_HOURS})"
        else
            echo -e "${YELLOW}WARN${NC} (Retention period not found or incorrect)"
        fi
    else
        echo -e "${RED}FAIL${NC} (Cannot retrieve Loki config)"
    fi
    
    # Test compactor
    echo -n "Testing Loki compactor... "
    local metrics=$(curl -s "${LOKI_URL}/metrics" 2>/dev/null)
    if [ $? -eq 0 ]; then
        if echo "$metrics" | grep -q "loki_compactor_runs_started_total"; then
            echo -e "${GREEN}PASS${NC} (Compactor metrics available)"
        else
            echo -e "${YELLOW}WARN${NC} (Compactor metrics not found)"
        fi
    else
        echo -e "${RED}FAIL${NC} (Cannot retrieve metrics)"
    fi
}

test_retention_alerts() {
    echo -e "\n${BLUE}=== Testing Retention Alert Rules ===${NC}"
    
    # Test alert rules
    echo -n "Testing retention alert rules... "
    local rules_response=$(curl -s "${PROMETHEUS_URL}/api/v1/rules" 2>/dev/null)
    if [ $? -eq 0 ]; then
        if echo "$rules_response" | jq -r '.data.groups[].rules[].alert' | grep -q "PrometheusStorageSpaceHigh"; then
            echo -e "${GREEN}PASS${NC} (Storage alerts found)"
        else
            echo -e "${YELLOW}WARN${NC} (Storage alerts not found)"
        fi
    else
        echo -e "${RED}FAIL${NC} (Cannot retrieve alert rules)"
    fi
    
    # Test Loki alerts
    echo -n "Testing Loki retention alerts... "
    if echo "$rules_response" | jq -r '.data.groups[].rules[].alert' | grep -q "LokiRetentionNotWorking"; then
        echo -e "${GREEN}PASS${NC} (Loki retention alerts found)"
    else
        echo -e "${YELLOW}WARN${NC} (Loki retention alerts not found)"
    fi
}

test_cleanup_script() {
    echo -e "\n${BLUE}=== Testing Cleanup Script ===${NC}"
    
    # Test cleanup script exists
    echo -n "Testing cleanup script... "
    if [ -f "/usr/local/bin/cleanup-monitoring-retention" ]; then
        echo -e "${GREEN}PASS${NC} (Script exists)"
    else
        echo -e "${RED}FAIL${NC} (Script not found)"
        return 1
    fi
    
    # Test cleanup script execution
    echo -n "Testing cleanup script execution... "
    if /usr/local/bin/cleanup-monitoring-retention --help >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC} (Script executable)"
    else
        echo -e "${RED}FAIL${NC} (Script not executable)"
    fi
}

test_disk_usage() {
    echo -e "\n${BLUE}=== Testing Disk Usage Monitoring ===${NC}"
    
    # Test monitoring directory
    echo -n "Testing monitoring data directory... "
    if [ -d "/opt/monitoring" ]; then
        local disk_usage=$(df -h /opt/monitoring | tail -1 | awk '{print $5}' | sed 's/%//')
        echo -e "${GREEN}PASS${NC} (${disk_usage}% used)"
    else
        echo -e "${RED}FAIL${NC} (Directory not found)"
        return 1
    fi
    
    # Test component directories
    echo -n "Testing Prometheus data directory... "
    if [ -d "/opt/monitoring/prometheus/data" ]; then
        local prom_size=$(du -sh /opt/monitoring/prometheus/data 2>/dev/null | cut -f1)
        echo -e "${GREEN}PASS${NC} (${prom_size:-0})"
    else
        echo -e "${YELLOW}WARN${NC} (Directory not found)"
    fi
    
    echo -n "Testing Loki data directory... "
    if [ -d "/opt/monitoring/loki" ]; then
        local loki_size=$(du -sh /opt/monitoring/loki 2>/dev/null | cut -f1)
        echo -e "${GREEN}PASS${NC} (${loki_size:-0})"
    else
        echo -e "${YELLOW}WARN${NC} (Directory not found)"
    fi
}

test_retention_metrics() {
    echo -e "\n${BLUE}=== Testing Retention Metrics ===${NC}"
    
    # Test Prometheus metrics
    echo -n "Testing Prometheus storage metrics... "
    local metrics_query="prometheus_tsdb_size_bytes"
    local metrics_response=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=${metrics_query}" 2>/dev/null)
    if [ $? -eq 0 ]; then
        local value=$(echo "$metrics_response" | jq -r '.data.result[0].value[1]')
        if [ "$value" != "null" ] && [ "$value" != "" ]; then
            echo -e "${GREEN}PASS${NC} (${value} bytes)"
        else
            echo -e "${YELLOW}WARN${NC} (No data)"
        fi
    else
        echo -e "${RED}FAIL${NC} (Cannot query metrics)"
    fi
    
    # Test Loki metrics
    echo -n "Testing Loki ingester metrics... "
    local loki_metrics=$(curl -s "${LOKI_URL}/metrics" 2>/dev/null)
    if [ $? -eq 0 ]; then
        if echo "$loki_metrics" | grep -q "loki_ingester_chunks_created_total"; then
            echo -e "${GREEN}PASS${NC} (Ingester metrics available)"
        else
            echo -e "${YELLOW}WARN${NC} (Ingester metrics not found)"
        fi
    else
        echo -e "${RED}FAIL${NC} (Cannot retrieve Loki metrics)"
    fi
}

show_retention_summary() {
    echo -e "\n${BLUE}=== Retention Configuration Summary ===${NC}"
    
    echo "Prometheus Retention: $EXPECTED_RETENTION (time) + 50GB (size)"
    echo "Loki Retention: $EXPECTED_RETENTION_HOURS (720 hours = 30 days)"
    echo "Compaction: Enabled for both services"
    echo "Monitoring: Alert rules and cleanup script deployed"
    echo "Cleanup Script: /usr/local/bin/cleanup-monitoring-retention"
    echo "Cron Job: Daily retention checks at 2 AM"
    
    echo -e "\n${BLUE}Manual Commands:${NC}"
    echo "Check retention status: cleanup-monitoring-retention --check"
    echo "Force cleanup: cleanup-monitoring-retention --force"
    echo "Compact Prometheus: cleanup-monitoring-retention --compact"
    echo "View logs: tail -f /var/log/monitoring-retention.log"
}

# Main execution
main() {
    echo "Starting retention policy validation..."
    
    # Run all tests
    test_prometheus_retention
    test_loki_retention
    test_retention_alerts
    test_cleanup_script
    test_disk_usage
    test_retention_metrics
    
    # Show summary
    show_retention_summary
    
    echo -e "\n${GREEN}✅ Retention policy testing completed!${NC}"
    echo "Review any FAIL or WARN messages above"
}

# Run main function
main "$@"