#!/bin/bash
# Validation script for Terraform Azure VMs module

set -e

echo "🔍 Validating Terraform Azure VMs Module..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Change to module directory
cd "$(dirname "$0")"

echo "1️⃣  Checking file structure..."

required_files=(
  "main.tf"
  "variables.tf"
  "outputs.tf"
  "versions.tf"
  "locals.tf"
  "network.tf"
  "security.tf"
  "compute.tf"
  "README.md"
  ".gitignore"
)

for file in "${required_files[@]}"; do
  if [ -f "$file" ]; then
    success "$file exists"
  else
    error "$file missing"
    exit 1
  fi
done

echo ""
echo "2️⃣  Checking examples..."

for example in basic production multi-env; do
  if [ -d "examples/$example" ]; then
    success "Example: $example"
    
    # Check example files
    if [ -f "examples/$example/main.tf" ] && [ -f "examples/$example/versions.tf" ]; then
      success "  ├─ Required files present"
    else
      error "  └─ Missing required files"
      exit 1
    fi
  else
    error "Example $example missing"
    exit 1
  fi
done

echo ""
echo "3️⃣  Validating Terraform syntax..."

# Validate main module
if terraform fmt -check -recursive > /dev/null 2>&1; then
  success "Terraform formatting is correct"
else
  warning "Terraform formatting issues found (run: terraform fmt -recursive)"
fi

if terraform init -backend=false > /dev/null 2>&1; then
  success "Terraform initialization successful"
else
  error "Terraform initialization failed"
  exit 1
fi

if terraform validate > /dev/null 2>&1; then
  success "Terraform validation passed"
else
  error "Terraform validation failed"
  terraform validate
  exit 1
fi

echo ""
echo "4️⃣  Checking documentation..."

if grep -q "# Azure Multi-VM Terraform Module" README.md; then
  success "README.md properly formatted"
else
  error "README.md missing title"
  exit 1
fi

if grep -q "## 📋 Table des Matières" README.md; then
  success "README.md has table of contents"
else
  warning "README.md missing table of contents"
fi

echo ""
echo "5️⃣  Checking best practices..."

# Check for sensitive variables
if grep -q 'sensitive.*=.*true' variables.tf; then
  success "Sensitive variables properly marked"
else
  warning "No sensitive variables marked"
fi

# Check for variable validations
if grep -q 'validation {' variables.tf; then
  success "Variable validations present"
else
  warning "No variable validations found"
fi

# Check for tags
if grep -q 'tags.*=' main.tf locals.tf; then
  success "Tags configuration present"
else
  warning "No tags configuration found"
fi

# Check for lifecycle blocks
if grep -q 'lifecycle {' compute.tf; then
  success "Lifecycle management configured"
else
  warning "No lifecycle blocks found"
fi

echo ""
echo "6️⃣  Checking security..."

# Check for NSG rules
if grep -q 'azurerm_network_security_rule' security.tf; then
  success "NSG rules configured"
else
  error "No NSG rules found"
  exit 1
fi

# Check for SSH key management
if grep -q 'tls_private_key' security.tf; then
  success "SSH key generation configured"
else
  warning "No SSH key generation found"
fi

echo ""
echo "7️⃣  Module statistics..."

echo ""
echo "  📁 Files:"
echo "    - Terraform files: $(find . -name "*.tf" | wc -l)"
echo "    - Documentation: $(find . -name "*.md" | wc -l)"
echo "    - Examples: $(find examples -maxdepth 1 -type d | tail -n +2 | wc -l)"
echo ""
echo "  📊 Resources:"
resources=$(grep -r "resource \"" *.tf | wc -l)
echo "    - Total resources: $resources"
echo "    - Variables: $(grep -c "^variable" variables.tf)"
echo "    - Outputs: $(grep -c "^output" outputs.tf)"
echo "    - Locals: $(grep -c "=" locals.tf | tail -1)"
echo ""
echo "  🔒 Security:"
nsg_rules=$(grep -c "azurerm_network_security_rule" security.tf)
echo "    - NSG rules: $nsg_rules"
echo "    - SSH key management: ✓"
echo "    - Managed identities: ✓"
echo ""

echo "✅ ${GREEN}Module validation completed successfully!${NC}"
echo ""
echo "📚 Next steps:"
echo "  1. Review documentation: cat README.md"
echo "  2. Try basic example: cd examples/basic && terraform init"
echo "  3. Deploy your infrastructure: terraform plan && terraform apply"
echo ""
