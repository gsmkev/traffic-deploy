# Traffic Management System - Docker Deployment

Simple Docker setup for deploying all traffic management microservices.

## Quick Start

### 1. Clone Repositories

```bash
./setup.sh
```

This clones all required repositories:
- `traffic-sync`
- `traffic-storage`
- `traffic-control`
- `traffic-sim`

### 2. Configure Environment

Copy the template and edit:

```bash
cp .env.template .env
nano .env
```

**Required variables:**
- `PRIVATE_KEY`: Your MetaMask private key (required)
- `EXECUTION_MODE`: Choose one:
  - `iot` - IoT device (no SUMO, local IPFS, no Pinata)
  - `web` - Web service (SUMO, Pinata, no local IPFS)
  - `local` - Local development (SUMO, local IPFS, no Pinata)

**For web mode, also set:**
- `PINATA_JWT`: Your Pinata JWT token
- `PINATA_URL`: Your Pinata gateway URL

### 3. Start Services

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

### 4. Check Status

```bash
docker compose ps
```

Services start in order:
1. PostgreSQL (waits for health check)
2. IPFS daemon (local/iot modes only)
3. traffic-sync (waits 20s after postgres)
4. traffic-storage (waits 20s after sync)
5. traffic-control (waits 20s after storage)
6. traffic-sim (waits 20s after control, web/local only)

### 5. View Logs

```bash
docker compose logs -f
```

### 6. Stop Services

```bash
docker compose down
```

## Service Ports

| Service | Port |
|---------|------|
| PostgreSQL | 5433 |
| IPFS API | 5001 |
| IPFS Gateway | 8080 |
| traffic-storage | 8000 |
| traffic-sim | 8001 |
| traffic-sync | 8002 |
| traffic-control | 8003 |

## Execution Modes

### IoT Mode (`EXECUTION_MODE=iot`)
- ✅ traffic-sync, traffic-storage, traffic-control
- ✅ Local IPFS (Kubo daemon)
- ❌ traffic-sim (no SUMO)
- ❌ Pinata

### Web Service Mode (`EXECUTION_MODE=web`)
- ✅ All services including traffic-sim
- ✅ SUMO installed
- ✅ Pinata for IPFS
- ❌ Local IPFS daemon

### Local Mode (`EXECUTION_MODE=local`)
- ✅ All services including traffic-sim
- ✅ SUMO installed
- ✅ Local IPFS (Kubo daemon)
- ❌ Pinata

## Troubleshooting

**Services not starting?**
```bash
docker compose logs [service-name]
```

**Database connection issues?**
```bash
docker compose exec postgres psql -U trafficuser -d trafficdb
```

**IPFS not working?**
```bash
docker compose exec ipfs ipfs swarm peers
```

**Rebuild containers:**
```bash
docker compose build --no-cache
docker compose up -d
```

