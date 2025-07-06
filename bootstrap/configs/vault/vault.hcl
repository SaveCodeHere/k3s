# ./configs/vault/vault.hcl
# HashiCorp Vault Server Configuration

# Storage Backend - File storage for simplicity
storage "file" {
  path = "/vault/data"
}

# TCP Listener Configuration
listener "tcp" {
  address         = "0.0.0.0:8200"
  tls_disable     = true  # Using Traefik for TLS termination
  
}

# UI Configuration
ui = true

# Logging
log_level = "INFO"
log_format = "standard"

# Disable mlock for container environments
disable_mlock = true

# API address
api_addr = "http://vault.nicstack.dev"


# Cluster configuration (for future scaling)
cluster_addr = "http://0.0.0.0:8201"

# Default lease TTL and max lease TTL
default_lease_ttl = "168h"  # 7 days
max_lease_ttl = "720h"      # 30 days

# Plugin directory
plugin_directory = "/vault/plugins"

# Raw storage endpoint (disable for security in production)
raw_storage_endpoint = false

# Introspection endpoint (disable for security in production)
introspection_endpoint = false

# Performance settings
cache_size = "32000"
