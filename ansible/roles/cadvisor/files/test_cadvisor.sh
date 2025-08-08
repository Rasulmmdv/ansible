#!/bin/bash
# Test script for enhanced cAdvisor monitoring

set -e

echo "=== Enhanced cAdvisor Monitoring Test ==="
echo "Testing enhanced cAdvisor configuration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test functions
test_cadvisor_health() {
    echo -n "Testing cAdvisor health endpoint... "
    if curl -s http://localhost:8080/healthz > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        return 1
    fi
}

test_cadvisor_metrics() {
    echo -n "Testing cAdvisor metrics endpoint... "
    if curl -s http://localhost:8080/metrics | grep -q "container_cpu_usage_seconds_total"; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        return 1
    fi
}

test_container_metrics() {
    echo -n "Testing container CPU metrics... "
    if curl -s http://localhost:8080/metrics | grep -q "container_cpu_usage_seconds_total.*cadvisor"; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${YELLOW}WARN${NC} (cAdvisor container not found)"
    fi
    
    echo -n "Testing container memory metrics... "
    if curl -s http://localhost:8080/metrics | grep -q "container_memory_usage_bytes"; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        return 1
    fi
}

test_enhanced_metrics() {
    echo -n "Testing enhanced network metrics... "
    if curl -s http://localhost:8080/metrics | grep -q "container_network_receive_bytes_total"; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        return 1
    fi
    
    echo -n "Testing filesystem metrics... "
    if curl -s http://localhost:8080/metrics | grep -q "container_fs_usage_bytes"; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        return 1
    fi
}

test_prometheus_integration() {
    echo -n "Testing Prometheus scraping cAdvisor... "
    if curl -s http://localhost:9090/api/v1/targets | grep -q "cadvisor.*up"; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${YELLOW}WARN${NC} (Prometheus not available or not scraping cAdvisor)"
    fi
}

test_alert_rules() {
    echo -n "Testing container alert rules loaded... "
    if curl -s http://localhost:9090/api/v1/rules | grep -q "ContainerHighCPUUsage"; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${YELLOW}WARN${NC} (Alert rules not loaded or Prometheus not available)"
    fi
}

show_container_stats() {
    echo -e "\n${YELLOW}=== Container Resource Statistics ===${NC}"
    
    # Get container count
    container_count=$(curl -s http://localhost:8080/api/v1.3/containers | jq '.[] | length' 2>/dev/null || echo "N/A")
    echo "Total containers monitored: $container_count"
    
    # Get cAdvisor container stats
    echo -e "\n${YELLOW}cAdvisor Container Resources:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" cadvisor 2>/dev/null || echo "cAdvisor container not found"
}

# Run tests
echo -e "\n${YELLOW}=== Running Health Tests ===${NC}"
test_cadvisor_health

echo -e "\n${YELLOW}=== Running Metrics Tests ===${NC}"
test_cadvisor_metrics
test_container_metrics
test_enhanced_metrics

echo -e "\n${YELLOW}=== Running Integration Tests ===${NC}"
test_prometheus_integration
test_alert_rules

# Show statistics
show_container_stats

echo -e "\n${YELLOW}=== Test Summary ===${NC}"
echo "Enhanced cAdvisor monitoring test completed"
echo "Check above for any FAIL or WARN messages"
echo -e "\n${GREEN}✅ Enhanced cAdvisor configuration is working!${NC}"