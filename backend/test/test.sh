#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# API Base URL
BASE_URL="http://localhost:3000"

# Function to print colored output
print_test() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to make API calls and check response
test_api() {
    local method=$1
    local endpoint=$2
    local data=$3
    local expected_status=$4
    local description=$5
    
    echo -e "\n${YELLOW}Testing: $description${NC}"
    echo "Request: $method $endpoint"
    
    if [ -n "$data" ]; then
        echo "Data: $data"
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X $method \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X $method \
            "$BASE_URL$endpoint")
    fi
    
    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo $response | sed -e 's/HTTPSTATUS\:.*//g')
    
    echo "Response Code: $http_code"
    echo "Response Body: $body" | jq . 2>/dev/null || echo "Response Body: $body"
    
    if [ "$http_code" -eq "$expected_status" ]; then
        print_success "Test passed"
    else
        print_error "Test failed - Expected: $expected_status, Got: $http_code"
    fi
}

# Check if API is running
check_api_health() {
    print_test "CHECKING API HEALTH"
    
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL/cars")
    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    echo "$http_code"
    if [ "$http_code" -eq 200 ]; then
        print_success "API is running"
        return 0
    else
        print_error "API is not accessible. Make sure it's running on $BASE_URL"
        return 1
    fi
}

# Main testing function
run_tests() {
    print_test "STARTING CARS API TESTS"
    
    # Test 1: Get all cars
    test_api "GET" "/cars" "" 200 "Get all cars"
    
    # Test 2: Get specific car
    test_api "GET" "/cars/1" "" 200 "Get car by ID"
    
    # Test 3: Get non-existent car
    test_api "GET" "/cars/999" "" 404 "Get non-existent car"
    
    # Test 4: Add new car
    new_car='{"make": "Tesla", "model": "Model 3", "year": 2023, "color": "Red", "price": 35000}'
    test_api "POST" "/cars" "$new_car" 201 "Add new car"
    
    # Test 5: Add car with missing fields
    invalid_car='{"make": "Tesla", "model": "Model S"}'
    test_api "POST" "/cars" "$invalid_car" 400 "Add car with missing fields"
    
    # Test 6: Update car
    update_data='{"price": 30000, "color": "Blue"}'
    test_api "PUT" "/cars/1" "$update_data" 200 "Update existing car"
    
    # Test 7: Update non-existent car
    test_api "PUT" "/cars/999" "$update_data" 404 "Update non-existent car"
    
    # Test 8: Search cars by make
    test_api "GET" "/cars/search?make=Toyota" "" 200 "Search cars by make"
    
    # Test 9: Search cars by price range
    test_api "GET" "/cars/search?min_price=20000&max_price=30000" "" 200 "Search cars by price range"
    
    # Test 10: Search with no results
    test_api "GET" "/cars/search?make=Lamborghini" "" 200 "Search with no results"
    
    # Test 11: Delete car
    test_api "DELETE" "/cars/2" "" 200 "Delete car"
    
    # Test 12: Delete non-existent car
    test_api "DELETE" "/cars/999" "" 200 "Delete non-existent car"
    
    # Test 13: Get home page
    test_api "GET" "/" "" 200 "Get home page"
    
    print_test "TESTS COMPLETED"
}

# Performance test
performance_test() {
    print_test "RUNNING PERFORMANCE TEST"
    
    echo "Making 10 concurrent requests to /cars endpoint..."
    
    start_time=$(date +%s.%N)
    
    for i in {1..10}; do
        curl -s "$BASE_URL/cars" > /dev/null &
    done
    
    wait
    
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    
    echo "10 concurrent requests completed in $duration seconds"
}

# Stress test
stress_test() {
    print_test "RUNNING STRESS TEST"
    
    echo "Adding 20 cars rapidly..."
    
    for i in {1..20}; do
        car_data=$(cat <<EOF
{
    "make": "TestCar$i",
    "model": "Model$i",
    "year": $((2020 + i % 4)),
    "color": "Color$i",
    "price": $((20000 + i * 1000))
}
EOF
)
        curl -s -X POST -H "Content-Type: application/json" \
            -d "$car_data" "$BASE_URL/cars" > /dev/null
        echo -n "."
    done
    
    echo ""
    echo "Stress test completed. Getting final car count..."
    
    response=$(curl -s "$BASE_URL/cars")
    count=$(echo "$response" | jq '. | length' 2>/dev/null || echo "Could not count cars")
    echo "Total cars in system: $count"
}

# Main execution
main() {
    echo -e "${GREEN}Cars API Testing Script${NC}"
    echo -e "${GREEN}======================${NC}"
    
    # Check if required tools are installed
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}Warning: jq not found. JSON responses won't be prettified${NC}"
    fi
    
    # Check API health first
    if ! check_api_health; then
        exit 1
    fi
    
    # Run tests based on arguments
    case "${1:-all}" in
        "basic")
            run_tests
            ;;
        "performance")
            performance_test
            ;;
        "stress")
            stress_test
            ;;
        "all")
            run_tests
            echo ""
            performance_test
            echo ""
            stress_test
            ;;
        *)
            echo "Usage: $0 [basic|performance|stress|all]"
            echo "  basic       - Run basic API tests"
            echo "  performance - Run performance tests"
            echo "  stress      - Run stress tests"
            echo "  all         - Run all tests (default)"
            exit 1
            ;;
    esac
    
    echo -e "\n${GREEN}All tests completed!${NC}"
}

main "$@"