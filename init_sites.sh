#!/bin/bash

# Initialize Alazab Sites
echo "🚀 Initializing Alazab Sites..."

# Wait for database
echo "⏳ Waiting for database..."
while ! mysqladmin ping -h mariadb -u root -padmin123 --silent; do
    sleep 2
done
echo "✅ Database is ready"

# Wait for Redis
echo "⏳ Waiting for Redis..."
while ! redis-cli -h redis ping; do
    sleep 2
done
echo "✅ Redis is ready"

# Create main site: alazab.local
echo "🏗️ Creating main site: alazab.local"
bench new-site alazab.local \
    --no-mariadb-socket \
    --mariadb-root-password admin123 \
    --admin-password admin123 \
    --verbose

# Install apps on main site
echo "📦 Installing apps on alazab.local"
bench --site alazab.local install-app erpnext
bench --site alazab.local install-app crm
bench --site alazab.local install-app hrms
bench --site alazab.local install-app helpdesk
bench --site alazab.local install-app webshop
bench --site alazab.local install-app drive
bench --site alazab.local install-app insights
bench --site alazab.local install-app books
bench --site alazab.local install-app print_designer
bench --site alazab.local install-app erpnext_price_estimation

# Create ERP site: erp.alazab.local
echo "🏗️ Creating ERP site: erp.alazab.local"
bench new-site erp.alazab.local \
    --no-mariadb-socket \
    --mariadb-root-password admin123 \
    --admin-password admin123 \
    --verbose

# Install ERP apps
echo "📦 Installing ERP apps on erp.alazab.local"
bench --site erp.alazab.local install-app erpnext
bench --site erp.alazab.local install-app hrms
bench --site erp.alazab.local install-app webshop
bench --site erp.alazab.local install-app books
bench --site erp.alazab.local install-app print_designer
bench --site erp.alazab.local install-app erpnext_price_estimation

# Create CRM site: crm.alazab.local
echo "🏗️ Creating CRM site: crm.alazab.local"
bench new-site crm.alazab.local \
    --no-mariadb-socket \
    --mariadb-root-password admin123 \
    --admin-password admin123 \
    --verbose

# Install CRM apps
echo "📦 Installing CRM apps on crm.alazab.local"
bench --site crm.alazab.local install-app crm
bench --site crm.alazab.local install-app helpdesk
bench --site crm.alazab.local install-app drive

# Set permissions
echo "🔐 Setting permissions"
bench --site alazab.local set-admin-password admin123
bench --site erp.alazab.local set-admin-password admin123
bench --site crm.alazab.local set-admin-password admin123

# Enable developer mode on main site
echo "🔧 Configuring development settings"
bench --site alazab.local set-config developer_mode 1
bench --site alazab.local set-config server_script_enabled 1
bench --site alazab.local set-config disable_website_cache 1

# Set production settings for ERP and CRM sites
bench --site erp.alazab.local set-config developer_mode 0
bench --site erp.alazab.local set-config disable_website_cache 0
bench --site crm.alazab.local set-config developer_mode 0
bench --site crm.alazab.local set-config disable_website_cache 0

# Migrate sites
echo "🔄 Running migrations"
bench --site alazab.local migrate
bench --site erp.alazab.local migrate
bench --site crm.alazab.local migrate

# Build assets
echo "🎨 Building assets"
bench build --app frappe
bench build --app erpnext
bench build --app crm

echo "✅ All sites initialized successfully!"
echo ""
echo "🌐 Access your sites:"
echo "   Main Site: http://alazab.local:8080"
echo "   ERP Site:  http://erp.alazab.local:8080" 
echo "   CRM Site:  http://crm.alazab.local:8080"
echo ""
echo "🔑 Login credentials:"
echo "   Username: Administrator"
echo "   Password: admin123"
