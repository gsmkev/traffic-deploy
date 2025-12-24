#!/bin/bash
set -e

cd /app

# Set UV link mode to copy to avoid hardlink warnings in Docker volumes
export UV_LINK_MODE=copy

# Make wait-for-it.sh executable
chmod +x /wait-for-it.sh 2>/dev/null || true

# Sync dependencies with uv
if [ -f "pyproject.toml" ]; then
    uv sync
elif [ -f "requirements.txt" ]; then
    # Fallback to requirements.txt if no pyproject.toml
    uv pip install --system -r requirements.txt
fi

# Wait for dependencies based on service
WAIT_TIMEOUT=120
EXECUTION_MODE=${EXECUTION_MODE:-web}

if [ "$SERVICE_NAME" = "sync" ]; then
    echo "🟡 [sync] Waiting for postgres..."
    /wait-for-it.sh postgres:5432 -t $WAIT_TIMEOUT
    echo "✅ [sync] postgres is ready"
elif [ "$SERVICE_NAME" = "storage" ]; then
    echo "🟡 [storage] Waiting for postgres..."
    /wait-for-it.sh postgres:5432 -t $WAIT_TIMEOUT
    echo "✅ [storage] postgres is ready"
    # Wait for sync if in local/iot mode
    if [ "$EXECUTION_MODE" != "web" ]; then
        echo "🟡 [storage] Waiting for traffic-sync..."
        /wait-for-it.sh traffic-sync:8002 -t $WAIT_TIMEOUT
        echo "✅ [storage] traffic-sync is ready"
    fi
elif [ "$SERVICE_NAME" = "control" ]; then
    echo "🟡 [control] Waiting for postgres..."
    /wait-for-it.sh postgres:5432 -t $WAIT_TIMEOUT
    echo "✅ [control] postgres is ready"
    echo "🟡 [control] Waiting for traffic-sync..."
    /wait-for-it.sh traffic-sync:8002 -t $WAIT_TIMEOUT
    echo "✅ [control] traffic-sync is ready"
    echo "🟡 [control] Waiting for traffic-storage..."
    /wait-for-it.sh traffic-storage:8000 -t $WAIT_TIMEOUT
    echo "✅ [control] traffic-storage is ready"
    
    # Initialize database
    if [ -f "auto_init_db.py" ]; then
        echo "🟡 [control] Initializing database..."
        uv run python auto_init_db.py || true
        echo "✅ [control] Database initialized"
    fi
elif [ "$SERVICE_NAME" = "sim" ]; then
    echo "🟡 [sim] Waiting for traffic-control..."
    /wait-for-it.sh traffic-control:8003 -t $WAIT_TIMEOUT
    echo "✅ [sim] traffic-control is ready"
    echo "🟡 [sim] Waiting for traffic-storage..."
    /wait-for-it.sh traffic-storage:8000 -t $WAIT_TIMEOUT
    echo "✅ [sim] traffic-storage is ready"
    echo "🟡 [sim] Waiting for traffic-sync..."
    /wait-for-it.sh traffic-sync:8002 -t $WAIT_TIMEOUT
    echo "✅ [sim] traffic-sync is ready"
fi

# For traffic-sim, start API server first, then run simulation after healthcheck
if [ "$SERVICE_NAME" = "sim" ] && [ -n "$SIM_FILE" ] && [ -f "$SIM_FILE" ]; then
    # Start API server in background
    echo "Starting API server for healthcheck..."
    uv run uvicorn api.server:app --host 0.0.0.0 --port ${SERVICE_PORT:-8000} &
    API_PID=$!
    
    # Wait for healthcheck to pass (server to be ready)
    echo "Waiting for API server to be ready..."
    for i in $(seq 1 30); do
        if curl -f http://localhost:${SERVICE_PORT:-8000}/healthcheck >/dev/null 2>&1; then
            echo "API server is ready! Starting simulation..."
            break
        fi
        sleep 1
    done
    
    # Run simulation directly
    echo "Starting simulation with file: $SIM_FILE"
    uv run python run_simulation.py "$SIM_FILE"
    
    # Keep API server running
    wait $API_PID
else
    # Start the service with uv run (API server)
    exec uv run uvicorn api.server:app --host 0.0.0.0 --port ${SERVICE_PORT:-8000}
fi

