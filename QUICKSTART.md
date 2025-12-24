# Quick Start Guide

## 1. Setup (One Time)

```bash
# Clone all repositories
./setup.sh

# Configure environment
cp .env.template .env
# Edit .env and set:
# - PRIVATE_KEY (required)
# - EXECUTION_MODE (iot/web/local)
# - PINATA_JWT and PINATA_URL (for web mode)
```

## 2. Start Services

**IoT Mode:**
```bash
docker compose --profile iot up -d
```

**Web Service Mode:**
```bash
docker compose --profile web up -d
```

**Local Mode:**
```bash
docker compose --profile local up -d
```

## 3. Verify

```bash
# Check all services are running
docker compose ps

# View logs
docker compose logs -f
```

## Startup Order

Services start automatically in this order with 20-second waits:

1. **PostgreSQL** → Ready
2. **IPFS** (local/iot only) → Ready  
3. **traffic-sync** → Waits 20s → Ready
4. **traffic-storage** → Waits 20s → Ready
5. **traffic-control** → Waits 40s → Ready
6. **traffic-sim** (web/local only) → Waits 20s → Ready

## Access Services

- Storage API: http://localhost:8000
- Sim API: http://localhost:8001
- Sync API: http://localhost:8002
- Control API: http://localhost:8003
- PostgreSQL: localhost:5433
- IPFS API: http://localhost:5001 (local/iot only)

## Stop Services

```bash
docker compose down
```

