#!/bin/bash

# Flutter Test Pilot - Comprehensive Test Runner
# This script runs all tests with proper organization and reporting

set -e

echo "🚀 Flutter Test Pilot - Test Runner"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_success "Flutter found: $(flutter --version | head -n 1)"
echo ""

# Parse command line arguments
RUN_UNIT=true
RUN_INTEGRATION=false
RUN_COMPREHENSIVE=false
COVERAGE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            RUN_UNIT=true
            RUN_INTEGRATION=true
            RUN_COMPREHENSIVE=true
            shift
            ;;
        --unit)
            RUN_UNIT=true
            RUN_INTEGRATION=false
            RUN_COMPREHENSIVE=false
            shift
            ;;
        --integration)
            RUN_UNIT=false
            RUN_INTEGRATION=true
            RUN_COMPREHENSIVE=false
            shift
            ;;
        --comprehensive)
            RUN_COMPREHENSIVE=true
            shift
            ;;
        --coverage)
            COVERAGE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Usage: ./test_runner.sh [--all|--unit|--integration|--comprehensive] [--coverage]"
            exit 1
            ;;
    esac
done

# Run Unit Tests
if [ "$RUN_UNIT" = true ]; then
    print_status "Running Unit Tests..."
    echo "======================================"
    
    if [ "$COVERAGE" = true ]; then
        print_status "With coverage report..."
        flutter test --coverage
        
        if command -v lcov &> /dev/null; then
            print_status "Generating HTML coverage report..."
            genhtml coverage/lcov.info -o coverage/html
            print_success "Coverage report generated at coverage/html/index.html"
        else
            print_warning "lcov not found. Install with: sudo apt-get install lcov (Linux) or brew install lcov (Mac)"
        fi
    else
        flutter test
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Unit tests passed!"
    else
        print_error "Unit tests failed!"
        exit 1
    fi
    echo ""
fi

# Run Integration Tests
if [ "$RUN_INTEGRATION" = true ]; then
    print_status "Running Integration Tests..."
    echo "======================================"
    
    # Check if devices are available
    print_status "Checking for connected devices..."
    DEVICES=$(flutter devices --machine | grep -c "\"id\"" || true)
    
    if [ "$DEVICES" -eq 0 ]; then
        print_warning "No devices found. Skipping integration tests."
        print_status "To run integration tests, connect a device or start an emulator"
    else
        print_success "Found $DEVICES device(s)"
        
        cd example
        flutter test integration_test/comprehensive_app_test.dart
        
        if [ $? -eq 0 ]; then
            print_success "Integration tests passed!"
        else
            print_error "Integration tests failed!"
            cd ..
            exit 1
        fi
        cd ..
    fi
    echo ""
fi

# Run Comprehensive Tests
if [ "$RUN_COMPREHENSIVE" = true ]; then
    print_status "Running Comprehensive Test Suite..."
    echo "======================================"
    
    dart test/comprehensive_test.dart
    
    if [ $? -eq 0 ]; then
        print_success "Comprehensive tests passed!"
    else
        print_error "Comprehensive tests failed!"
        exit 1
    fi
    echo ""
fi

# Summary
echo ""
echo "======================================"
print_success "All requested tests completed!"
echo "======================================"
echo ""

# Show coverage if generated
if [ "$COVERAGE" = true ] && [ -f "coverage/lcov.info" ]; then
    print_status "Coverage Summary:"
    if command -v lcov &> /dev/null; then
        lcov --summary coverage/lcov.info
    else
        print_status "View coverage report at: coverage/html/index.html"
    fi
fi
