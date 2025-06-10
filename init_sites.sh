#!/bin/bash

# Alazab Sites Initialization Script
echo "🚀 Initializing Alazab Complete System..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Wait for database
print_info "Waiting for MariaDB database..."
while ! mysqladmin ping -h mariadb -u root -padmin123 --silent; do
    echo "⏳ Database not ready yet, waiting 5 seconds..."
    sleep 5
done
print_status "Database is ready"

# Wait for Redis
print_info "Waiting for Redis cache..."
while ! redis-cli -h redis ping > /dev/null 2>&1; do
    echo "⏳ Redis not ready yet, waiting 5 seconds..."
    sleep 5
done
print_status "Redis is ready"

# Get into the container and run commands
CONTAINER_ID=$(docker ps --filter "name=alazab.*backend" --format "{{.ID}}" | head -n1)

if [ -z "$CONTAINER_ID" ]; then
    print_error "Backend container not found! Make sure docker-compose is running."
    exit 1
fi

print_info "Using backend container: $CONTAINER_ID"

# Function to run bench commands in container
run_bench() {
    docker exec -it $CONTAINER_ID bash -c "$1"
}

# Create main site: alazab.local
print_info "Creating main site: alazab.local"
run_bench "cd /home/frappe/frappe-bench && bench new-site alazab.local --no-mariadb-socket --mariadb-root-password admin123 --admin-password admin123 --verbose"

if [ $? -eq 0 ]; then
    print_status "Main site created successfully"
else
    print_error "Failed to create main site"
    exit 1
fi

# Install apps on main site
print_info "Installing applications on alazab.local"

APPS=("erpnext" "hrms" "books" "crm" "helpdesk" "erpnext_price_estimation")

for app in "${APPS[@]}"; do
    print_info "Installing $app..."
    run_bench "cd /home/frappe/frappe-bench && bench --site alazab.local install-app $app"
    if [ $? -eq 0 ]; then
        print_status "$app installed successfully"
    else
        print_warning "$app installation failed (might not be available yet)"
    fi
done

# Create ERP site: erp.alazab.local
print_info "Creating ERP site: erp.alazab.local"
run_bench "cd /home/frappe/frappe-bench && bench new-site erp.alazab.local --no-mariadb-socket --mariadb-root-password admin123 --admin-password admin123 --verbose"

if [ $? -eq 0 ]; then
    print_status "ERP site created successfully"
    
    # Install ERP apps
    print_info "Installing ERP applications on erp.alazab.local"
    ERP_APPS=("erpnext" "hrms" "books" "erpnext_price_estimation")
    
    for app in "${ERP_APPS[@]}"; do
        print_info "Installing $app on ERP site..."
        run_bench "cd /home/frappe/frappe-bench && bench --site erp.alazab.local install-app $app"
        if [ $? -eq 0 ]; then
            print_status "$app installed on ERP site"
        else
            print_warning "$app installation failed on ERP site"
        fi
    done
else
    print_warning "ERP site creation failed, continuing with main site only"
fi

# Create CRM site: crm.alazab.local
print_info "Creating CRM site: crm.alazab.local"
run_bench "cd /home/frappe/frappe-bench && bench new-site crm.alazab.local --no-mariadb-socket --mariadb-root-password admin123 --admin-password admin123 --verbose"

if [ $? -eq 0 ]; then
    print_status "CRM site created successfully"
    
    # Install CRM apps
    print_info "Installing CRM applications on crm.alazab.local"
    CRM_APPS=("crm" "helpdesk")
    
    for app in "${CRM_APPS[@]}"; do
        print_info "Installing $app on CRM site..."
        run_bench "cd /home/frappe/frappe-bench && bench --site crm.alazab.local install-app $app"
        if [ $? -eq 0 ]; then
            print_status "$app installed on CRM site"
        else
            print_warning "$app installation failed on CRM site"
        fi
    done
else
    print_warning "CRM site creation failed, continuing without CRM site"
fi

# Configure sites
print_info "Configuring sites..."

# Set development mode on main site
run_bench "cd /home/frappe/frappe-bench && bench --site alazab.local set-config developer_mode 1"
run_bench "cd /home/frappe/frappe-bench && bench --site alazab.local set-config server_script_enabled 1"
run_bench "cd /home/frappe/frappe-bench && bench --site alazab.local set-config disable_website_cache 1"

# Set production settings for other sites
run_bench "cd /home/frappe/frappe-bench && bench --site erp.alazab.local set-config developer_mode 0" 2>/dev/null
run_bench "cd /home/frappe/frappe-bench && bench --site erp.alazab.local set-config disable_website_cache 0" 2>/dev/null
run_bench "cd /home/frappe/frappe-bench && bench --site crm.alazab.local set-config developer_mode 0" 2>/dev/null
run_bench "cd /home/frappe/frappe-bench && bench --site crm.alazab.local set-config disable_website_cache 0" 2>/dev/null

# Run migrations
print_info "Running database migrations..."
run_bench "cd /home/frappe/frappe-bench && bench --site alazab.local migrate"
run_bench "cd /home/frappe/frappe-bench && bench --site erp.alazab.local migrate" 2>/dev/null
run_bench "cd /home/frappe/frappe-bench && bench --site crm.alazab.local migrate" 2>/dev/null

# Build assets
print_info "Building frontend assets..."
run_bench "cd /home/frappe/frappe-bench && bench build --app frappe"
run_bench "cd /home/frappe/frappe-bench && bench build --app erpnext"

# Final status
print_status "🎉 Alazab system initialization completed!"
echo ""
echo "🌐 Access your sites:"
echo "   Main Site:  http://alazab.local:8080"
echo "   ERP Site:   http://erp.alazab.local:8080" 
echo "   CRM Site:   http://crm.alazab.local:8080"
echo ""
echo "🔑 Login credentials:"
echo "   Username: Administrator"
echo "   Password: admin123"
echo ""
echo "🏢 Company: Alazab Construction & Engineering"
echo "💰 Currency: EGP (Egyptian Pound)"
echo "🌍 Country: Egypt"
echo ""
print_info "Add these entries to your /etc/hosts file:"
echo "127.0.0.1 alazab.local"
echo "127.0.0.1 erp.alazab.local"
echo "127.0.0.1 crm.alazab.local"
