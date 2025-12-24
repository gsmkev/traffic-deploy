#!/bin/bash
set -e

# Wait for IPFS API to be ready
echo "Waiting for IPFS API to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:5001/api/v0/version > /dev/null 2>&1; then
        echo "IPFS API is ready"
        break
    fi
    sleep 1
done

# Disable AutoConf using IPFS API
echo "Disabling AutoConf in IPFS configuration..."
curl -X POST "http://localhost:5001/api/v0/config?arg=Autoconf.Enabled&arg=false" > /dev/null 2>&1 || true
echo "AutoConf disabled successfully"

