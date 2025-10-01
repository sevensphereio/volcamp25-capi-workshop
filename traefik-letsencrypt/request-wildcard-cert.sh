#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 -d DOMAIN -e EMAIL -p DNS_PROVIDER [OPTIONS]

Request wildcard SSL certificates using certbot with DNS-01 challenge.

Required arguments:
  -d DOMAIN        Domain name (e.g., example.com)
  -e EMAIL         Email address for Let's Encrypt notifications
  -p DNS_PROVIDER  DNS provider (cloudflare, ovh, route53, google, digitalocean, azure)

Optional arguments:
  -s              Use Let's Encrypt staging server (for testing)
  -h              Display this help message

Supported DNS providers:
  - cloudflare    : Cloudflare DNS (requires CF_DNS_API_TOKEN)
  - ovh           : OVH DNS (requires OVH credentials)
  - route53       : AWS Route53 (requires AWS credentials)
  - google        : Google Cloud DNS (requires GCP credentials)
  - digitalocean  : DigitalOcean DNS (requires DO_AUTH_TOKEN)
  - azure         : Azure DNS (requires Azure credentials)

Examples:
  # Production certificate with Cloudflare
  $0 -d example.com -e admin@example.com -p cloudflare

  # Test with staging server
  $0 -d example.com -e admin@example.com -p cloudflare -s

Environment variables required by DNS provider:
  Cloudflare:    CF_DNS_API_TOKEN
  OVH:           OVH_ENDPOINT, OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY
  Route53:       AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
  Google Cloud:  GCE_PROJECT, GOOGLE_APPLICATION_CREDENTIALS
  DigitalOcean:  DO_AUTH_TOKEN
  Azure:         AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID

EOF
}

# Default values
STAGING=""
DOMAIN=""
EMAIL=""
DNS_PROVIDER=""

# Parse command line arguments
while getopts "d:e:p:sh" opt; do
    case $opt in
        d) DOMAIN="$OPTARG" ;;
        e) EMAIL="$OPTARG" ;;
        p) DNS_PROVIDER="$OPTARG" ;;
        s) STAGING="--staging" ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

# Validate required arguments
if [[ -z "$DOMAIN" || -z "$EMAIL" || -z "$DNS_PROVIDER" ]]; then
    print_error "Missing required arguments"
    usage
    exit 1
fi

# Validate DNS provider
case "$DNS_PROVIDER" in
    cloudflare|ovh|route53|google|digitalocean|azure)
        ;;
    *)
        print_error "Unsupported DNS provider: $DNS_PROVIDER"
        print_info "Supported providers: cloudflare, ovh, route53, google, digitalocean, azure"
        exit 1
        ;;
esac

print_info "=== Wildcard Certificate Request ==="
print_info "Domain: $DOMAIN (*.${DOMAIN})"
print_info "Email: $EMAIL"
print_info "DNS Provider: $DNS_PROVIDER"
[[ -n "$STAGING" ]] && print_warning "Using STAGING server (certificates will not be trusted)"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Create directories for certificates
CERT_DIR="$(pwd)/certs/certbot"
mkdir -p "$CERT_DIR"/{live,archive,renewal}

print_info "Certificate directory: $CERT_DIR"

# Prepare Docker command based on DNS provider
DOCKER_CMD="docker run -it --rm \
    -v $CERT_DIR:/etc/letsencrypt \
    -v $CERT_DIR/logs:/var/log/letsencrypt"

# Add environment variables based on DNS provider
case "$DNS_PROVIDER" in
    cloudflare)
        if [[ -z "$CF_DNS_API_TOKEN" ]]; then
            print_error "CF_DNS_API_TOKEN environment variable is not set"
            print_info "Set it with: export CF_DNS_API_TOKEN='your-token'"
            exit 1
        fi
        DOCKER_CMD="$DOCKER_CMD -e CF_DNS_API_TOKEN=$CF_DNS_API_TOKEN"
        PLUGIN="certbot/dns-cloudflare"
        DNS_ARG="--dns-cloudflare --dns-cloudflare-credentials /dev/null"
        ;;

    ovh)
        if [[ -z "$OVH_ENDPOINT" || -z "$OVH_APPLICATION_KEY" || -z "$OVH_APPLICATION_SECRET" || -z "$OVH_CONSUMER_KEY" ]]; then
            print_error "OVH credentials are not fully set"
            print_info "Required: OVH_ENDPOINT, OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY"
            exit 1
        fi
        DOCKER_CMD="$DOCKER_CMD \
            -e OVH_ENDPOINT=$OVH_ENDPOINT \
            -e OVH_APPLICATION_KEY=$OVH_APPLICATION_KEY \
            -e OVH_APPLICATION_SECRET=$OVH_APPLICATION_SECRET \
            -e OVH_CONSUMER_KEY=$OVH_CONSUMER_KEY"
        PLUGIN="certbot/dns-ovh"
        DNS_ARG="--dns-ovh"
        ;;

    route53)
        if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
            print_error "AWS credentials are not set"
            print_info "Required: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
            exit 1
        fi
        DOCKER_CMD="$DOCKER_CMD \
            -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
            -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
            -e AWS_REGION=${AWS_REGION:-us-east-1}"
        PLUGIN="certbot/dns-route53"
        DNS_ARG="--dns-route53"
        ;;

    google)
        if [[ -z "$GCE_PROJECT" || -z "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
            print_error "Google Cloud credentials are not set"
            print_info "Required: GCE_PROJECT, GOOGLE_APPLICATION_CREDENTIALS"
            exit 1
        fi
        DOCKER_CMD="$DOCKER_CMD \
            -e GCE_PROJECT=$GCE_PROJECT \
            -v $GOOGLE_APPLICATION_CREDENTIALS:/tmp/credentials.json:ro \
            -e GOOGLE_APPLICATION_CREDENTIALS=/tmp/credentials.json"
        PLUGIN="certbot/dns-google"
        DNS_ARG="--dns-google"
        ;;

    digitalocean)
        if [[ -z "$DO_AUTH_TOKEN" ]]; then
            print_error "DO_AUTH_TOKEN environment variable is not set"
            print_info "Set it with: export DO_AUTH_TOKEN='your-token'"
            exit 1
        fi
        DOCKER_CMD="$DOCKER_CMD -e DO_AUTH_TOKEN=$DO_AUTH_TOKEN"
        PLUGIN="certbot/dns-digitalocean"
        DNS_ARG="--dns-digitalocean"
        ;;

    azure)
        if [[ -z "$AZURE_CLIENT_ID" || -z "$AZURE_CLIENT_SECRET" || -z "$AZURE_SUBSCRIPTION_ID" || -z "$AZURE_TENANT_ID" ]]; then
            print_error "Azure credentials are not fully set"
            print_info "Required: AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID"
            exit 1
        fi
        DOCKER_CMD="$DOCKER_CMD \
            -e AZURE_CLIENT_ID=$AZURE_CLIENT_ID \
            -e AZURE_CLIENT_SECRET=$AZURE_CLIENT_SECRET \
            -e AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
            -e AZURE_TENANT_ID=$AZURE_TENANT_ID"
        PLUGIN="certbot/dns-azure"
        DNS_ARG="--dns-azure"
        ;;
esac

print_info "Pulling certbot Docker image: $PLUGIN"
docker pull "$PLUGIN"

print_info "Requesting wildcard certificate..."
print_warning "You may need to wait 30-90 seconds for DNS propagation"

# Execute certbot
eval "$DOCKER_CMD $PLUGIN certonly \
    $DNS_ARG \
    $STAGING \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    -d $DOMAIN \
    -d *.$DOMAIN \
    --preferred-challenges dns-01"

if [[ $? -eq 0 ]]; then
    print_info "✅ Certificate successfully obtained!"
    print_info ""
    print_info "Certificate files location:"
    print_info "  - Certificate:    $CERT_DIR/live/$DOMAIN/fullchain.pem"
    print_info "  - Private Key:    $CERT_DIR/live/$DOMAIN/privkey.pem"
    print_info "  - Chain:          $CERT_DIR/live/$DOMAIN/chain.pem"
    print_info "  - Full cert:      $CERT_DIR/live/$DOMAIN/cert.pem"
    print_info ""

    # Display certificate information
    if command -v openssl &> /dev/null; then
        print_info "Certificate details:"
        openssl x509 -in "$CERT_DIR/live/$DOMAIN/cert.pem" -noout -text | grep -A 2 "Subject:\|Issuer:\|Not Before\|Not After\|DNS:"
    fi

    print_info ""
    print_info "To renew the certificate in the future, run:"
    print_info "  $0 -d $DOMAIN -e $EMAIL -p $DNS_PROVIDER"

    # Set proper permissions
    chmod 600 "$CERT_DIR/live/$DOMAIN/privkey.pem"

else
    print_error "❌ Certificate request failed"
    print_info "Check logs in: $CERT_DIR/logs/"
    exit 1
fi
