#!/bin/bash

# Verification script for remote monitoring setup
# This script checks if the Nginx Exporter and related services are working correctly

set -e

echo "=== Remote Monitoring Verification Script ==="
echo "Running on: $(hostname)"
echo "Date: $(date)"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}[OK]${NC} $message"
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}[WARNING]${NC} $message"
    elif [ "$status" = "INFO" ]; then
        echo -e "${BLUE}[INFO]${NC} $message"
    else
        echo -e "${RED}[ERROR]${NC} $message"
    fi
}

# Check if Docker is running
echo "1. Checking Docker service..."
if systemctl is-active --quiet docker; then
    print_status "OK" "Docker is running"
else
    print_status "ERROR" "Docker is not running"
    exit 1
fi

# Check if Nginx Docker container is running
echo "2. Checking Nginx Docker container..."
if docker ps --format "table {{.Names}}" | grep -q "nginx"; then
    print_status "OK" "Nginx Docker container is running"
    nginx_container=$(docker ps --format "table {{.Names}}" | grep "nginx" | head -1)
    print_status "OK" "Nginx container: $nginx_container"
else
    print_status "ERROR" "Nginx Docker container is not running. Please start your Docker-based Nginx before running this role."
    exit 1
fi

# Check Nginx stub_status endpoint
echo "3. Checking Nginx stub_status endpoint..."
if curl -s -f "http://localhost:80/nginx_status" > /dev/null; then
    print_status "OK" "Nginx stub_status endpoint is accessible"
    echo "   stub_status output:"
    curl -s "http://localhost:80/nginx_status" | sed 's/^/   /'
else
    print_status "ERROR" "Nginx stub_status endpoint is not accessible"
    exit 1
fi

# Check if Nginx Exporter container is running
echo "4. Checking Nginx Exporter container..."
if docker ps --format "table {{.Names}}" | grep -q "nginx_exporter"; then
    print_status "OK" "Nginx Exporter container is running"
else
    print_status "ERROR" "Nginx Exporter container is not running"
    exit 1
fi

# Check Nginx Exporter metrics endpoint
echo "5. Checking Nginx Exporter metrics endpoint..."
if curl -s -f "http://localhost:9113/metrics" > /dev/null; then
    print_status "OK" "Nginx Exporter metrics endpoint is accessible"
    
    # Check for key metrics
    echo "   Checking for key metrics:"
    if curl -s "http://localhost:9113/metrics" | grep -q "nginx_requests_total"; then
        print_status "OK" "nginx_requests_total metric found"
    else
        print_status "WARNING" "nginx_requests_total metric not found"
    fi
    
    if curl -s "http://localhost:9113/metrics" | grep -q "nginx_connections_active"; then
        print_status "OK" "nginx_connections_active metric found"
    else
        print_status "WARNING" "nginx_connections_active metric not found"
    fi
else
    print_status "ERROR" "Nginx Exporter metrics endpoint is not accessible"
    exit 1
fi

# Check Docker network
echo "6. Checking Docker monitoring network..."
if docker network ls --format "table {{.Name}}" | grep -q "monitoring"; then
    print_status "OK" "Docker monitoring network exists"
else
    print_status "WARNING" "Docker monitoring network does not exist"
fi

# Check if port 9113 is listening
echo "7. Checking if port 9113 is listening..."
if netstat -tlnp 2>/dev/null | grep -q ":9113 "; then
    print_status "OK" "Port 9113 is listening"
else
    print_status "WARNING" "Port 9113 is not listening (may be normal if using Docker)"
fi

# Check firewall status (if available)
echo "8. Checking firewall status..."
if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
        print_status "WARNING" "UFW firewall is active - ensure port 9113 is allowed"
    else
        print_status "OK" "UFW firewall is not active"
    fi
elif command -v firewall-cmd >/dev/null 2>&1; then
    if firewall-cmd --state | grep -q "running"; then
        print_status "WARNING" "firewalld is running - ensure port 9113 is allowed"
    else
        print_status "OK" "firewalld is not running"
    fi
else
    print_status "OK" "No firewall detected"
fi

# Check network connectivity to monitoring server
echo "9. Checking network connectivity..."
if [ -n "$MONITORING_SERVER_HOST" ]; then
    print_status "INFO" "Monitoring server host: $MONITORING_SERVER_HOST"
    if ping -c 1 "$MONITORING_SERVER_HOST" >/dev/null 2>&1; then
        print_status "OK" "Can reach monitoring server: $MONITORING_SERVER_HOST"
    else
        print_status "WARNING" "Cannot reach monitoring server: $MONITORING_SERVER_HOST"
    fi
else
    print_status "INFO" "MONITORING_SERVER_HOST not set - skipping connectivity check"
fi

echo
echo "=== Verification Summary ==="
echo "If all checks passed, your remote monitoring setup should be working correctly."
echo
echo "To verify from the monitoring server:"
echo "1. Check Prometheus targets: http://monitoring-server:9090/targets"
echo "2. Look for the 'nginx_remote' job"
echo "3. Verify metrics are being collected"
echo
echo "To view Nginx metrics in Grafana:"
echo "1. Import dashboard ID 12707"
echo "2. Or create custom queries using nginx_* metrics"
echo
echo "Common Prometheus queries:"
echo "- nginx_requests_total"
echo "- nginx_connections_active"
echo "- rate(nginx_requests_total[5m])"
echo
echo "Verification completed at: $(date)" 