#!/bin/sh
set -e

# Function to disable AutoConf
disable_autoconf() {
    if [ -f /data/ipfs/config ]; then
        echo "Disabling AutoConf in IPFS configuration..."
        if command -v jq > /dev/null 2>&1; then
            jq '.Autoconf.Enabled = false' /data/ipfs/config > /data/ipfs/config.tmp && mv /data/ipfs/config.tmp /data/ipfs/config
        else
            # Fallback: use sed (works for simple JSON modifications)
            sed -i 's/"Enabled":\s*true/"Enabled": false/g' /data/ipfs/config 2>/dev/null || \
            sed -i 's/"Enabled": true/"Enabled": false/g' /data/ipfs/config 2>/dev/null || true
        fi
        echo "AutoConf disabled in config"
        return 0
    fi
    return 1
}

# Try to disable AutoConf before starting (if config exists)
disable_autoconf || true

# Start IPFS daemon in background
ipfs daemon &
IPFS_PID=$!

# If config didn't exist, wait for IPFS to initialize and disable via API
if [ ! -f /data/ipfs/config ]; then
    echo "Waiting for IPFS to initialize..."
    for i in $(seq 1 30); do
        if [ -f /data/ipfs/config ]; then
            sleep 2
            disable_autoconf || true
            break
        fi
        sleep 1
    done
    
    # Also try via API as backup
    echo "Waiting for IPFS API..."
    for i in $(seq 1 30); do
        if curl -s http://localhost:5001/api/v0/version > /dev/null 2>&1; then
            echo "Disabling AutoConf via API..."
            curl -X POST "http://localhost:5001/api/v0/config?arg=Autoconf.Enabled&arg=false" > /dev/null 2>&1 || true
            break
        fi
        sleep 1
    done
fi

# Keep container running
wait $IPFS_PID

