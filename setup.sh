#!/bin/bash
set -e

echo "📥 Cloning repositories..."

# Read execution mode from .env if it exists
if [ -f ".env" ]; then
    EXECUTION_MODE=$(grep "^EXECUTION_MODE=" .env | cut -d '=' -f2 | tr -d '"' | tr -d "'")
else
    EXECUTION_MODE="web"
fi

mkdir -p traffic-sync traffic-storage traffic-control traffic-sim

if [ ! -d "traffic-sync/.git" ]; then
    echo "Cloning traffic-sync..."
    git clone https://github.com/pinv01-25/traffic-sync.git traffic-sync
else
    echo "traffic-sync already exists, skipping..."
fi

if [ ! -d "traffic-storage/.git" ]; then
    echo "Cloning traffic-storage..."
    if [ "$EXECUTION_MODE" = "iot" ] || [ "$EXECUTION_MODE" = "local" ]; then
        echo "Using jetson branch for local IPFS support..."
        git clone -b jetson https://github.com/pinv01-25/traffic-storage.git traffic-storage || \
        git clone https://github.com/pinv01-25/traffic-storage.git traffic-storage
    else
        git clone https://github.com/pinv01-25/traffic-storage.git traffic-storage
    fi
else
    echo "traffic-storage already exists, skipping..."
fi

if [ ! -d "traffic-control/.git" ]; then
    echo "Cloning traffic-control..."
    git clone https://github.com/pinv01-25/traffic-control.git traffic-control
else
    echo "traffic-control already exists, skipping..."
fi

if [ ! -d "traffic-sim/.git" ]; then
    echo "Cloning traffic-sim..."
    git clone https://github.com/pinv01-25/traffic-sim.git traffic-sim
else
    echo "traffic-sim already exists, skipping..."
fi

echo "✅ All repositories cloned!"

