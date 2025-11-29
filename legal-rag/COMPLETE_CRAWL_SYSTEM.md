# ALMQUIST Legal RAG - Complete Crawl System

**Status:** ✅ PRODUCTION - RUNNING
**Version:** 2.0
**Date:** 2025-11-30
**Coverage:** ALL Czech Courts (~546,000+ decisions)

---

## 🎯 Overview

Kompletní autonomní systém pro crawlování **VŠECH českých soudů** včetně:
- **Nejvyšší soud (NS)** - specializovaná sbírka
- **Všechny soudy ČR** - přes oficiální Justice.cz API
- **Resource monitoring** - CPU, GPU, Disk, Memory
- **Paralelní běh** - 2 crawlery současně
- **Auto-stop** - při překročení limitů

---

## 📊 Data Coverage

### Justice.cz API - ALL COURTS
**Total: ~546,000 rozhodnutí** (2020-2025)

```
2021: 150,940 rozhodnutí
2022: 181,864 rozhodnutí
2023:  85,465 rozhodnutí
2024:  61,217 rozhodnutí
2025:  66,576 rozhodnutí
```

**Pokryté soudy:**
- ✅ Nejvyšší soud (NS)
- ✅ Ústavní soud (ÚS)
- ✅ Nejvyšší správní soud (NSS)
- ✅ Vrchní soud v Praze
- ✅ Vrchní soud v Olomouci
- ✅ Všechny krajské soudy (15)
- ✅ Všechny okresní soudy

### NS Specialized Collection
**Sbírka.nsoud.cz:** ~1,328 stránek specializované sbírky

---

## 🚀 Running Crawlers

### Current Status

```bash
screen -ls
```

**Active crawlers:**
1. `ns_supreme` - NS specialized collection
2. `justice_all` - ALL courts via API

### Monitor Progress

```bash
# Attach to NS crawler
screen -r ns_supreme

# Attach to Justice API crawler
screen -r justice_all

# Check database
sqlite3 /home/puzik/almquist_legal_sources.db \
  "SELECT COUNT(*) FROM court_decisions"

# Resource status
python3 /home/puzik/almquist_resource_monitor.py
```

---

## 📁 Components

### 1. Resource Monitor (`almquist_resource_monitor.py`)

Monitors system resources and enforces limits:
- **CPU:** ≤ 80%
- **GPU:** ≤ 80%
- **Disk:** ≤ 90%
- **Memory:** ≤ 85%

**Usage:**
```python
from almquist_resource_monitor import ResourceMonitor

monitor = ResourceMonitor()
if not monitor.check_all():
    print("Resource limits exceeded!")
```

### 2. Justice API Crawler (`almquist_justice_api_crawler.py`)

Crawls ALL Czech courts via official REST API.

**Features:**
- REST API: `https://rozhodnuti.justice.cz/api/opendata`
- Pagination: 100 decisions per page
- Hierarchical: year → month → day → page
- Metadata: ECLI, keywords, affected laws
- Full text: Available via detail endpoint

**API Structure:**
```
GET /api/opendata                  → years list
GET /api/opendata/2024            → months in 2024
GET /api/opendata/2024/11         → days in Nov 2024
GET /api/opendata/2024/11/29?page=0 → decisions on day
```

**Run:**
```bash
python3 almquist_justice_api_crawler.py
```

### 3. NS Specialized Crawler (`almquist_legal_court_decisions_crawler.py`)

Crawls NS specialized collection (sbírka rozhodnutí).

**Features:**
- Archive URL: `/nove-vydana-rozhodnuti-ve-sbirka/`
- Pagination: `/strana/{page}/`
- ~1,328 pages available
- Detailed case information

**Run:**
```bash
python3 almquist_legal_court_decisions_crawler.py
```

---

## ⚙️ Configuration

### Pause Between Requests
```python
self.pause_between_requests = 30  # seconds
```

**Rationale:** 30 seconds ensures we don't overload court servers.

### Resource Limits
```python
ResourceMonitor(
    cpu_limit=80,    # CPU usage %
    disk_limit=90,   # Disk usage %
    mem_limit=85,    # Memory usage %
    gpu_limit=80     # GPU usage %
)
```

**Auto-stop:** Crawlers automatically stop if any limit is exceeded.

---

## 🗂️ Database Schema

**Table: `court_decisions`**

```sql
CREATE TABLE court_decisions (
    id INTEGER PRIMARY KEY,
    case_number TEXT,           -- Jednací číslo
    court_level TEXT,           -- supreme/appellate/regional/district
    court_name TEXT,            -- Název soudu
    decision_type TEXT,         -- rozsudek/usnesení/nález
    decision_date TEXT,         -- Datum vydání
    ecli TEXT UNIQUE,           -- ECLI identifier
    keywords TEXT,              -- JSON array
    affected_laws TEXT,         -- JSON array
    summary TEXT,               -- Předmět řízení
    full_text TEXT,             -- Celé rozhodnutí
    source_url TEXT,            -- URL zdroje
    added_to_rag INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

---

## 📈 Expected Timeline

### NS Crawler
- Pages: 1,328
- Pause: 30s/page
- Minimum: ~11 hours (pauses only)
- **Estimate: 15-20 hours**

### Justice API Crawler
- Decisions: ~546,000
- Requests: ~5,460 (100/page)
- Pause: 30s/request
- Minimum: ~45 hours (pauses only)
- **Estimate: 50-70 hours (2-3 days)**

---

## 🔄 Workflow

```
1. NS Crawler (ns_supreme)
   ↓
   Crawls sbirka.nsoud.cz
   ↓
   Saves to almquist_legal_sources.db
   ↓
   Monitors CPU/GPU/Disk/Memory
   ↓
   Auto-stops if limits exceeded

2. Justice API Crawler (justice_all)
   ↓
   Fetches available years
   ↓
   For each year → month → day
   ↓
   Paginates through decisions (100/page)
   ↓
   Saves metadata + full text
   ↓
   Monitors resources
   ↓
   Auto-stops if limits exceeded

3. After Completion
   ↓
   Run RAG integration
   ↓
   python3 almquist_legal_rag_integration.py
   ↓
   Generates embeddings for ALL decisions
   ↓
   Updates FAISS index
```

---

## 🎯 Integration to RAG

After crawlers complete:

```bash
# Integrate all new decisions into RAG
python3 /home/puzik/almquist_legal_rag_integration.py

# Check statistics
python3 /home/puzik/almquist_legal_stats.py

# Run test suite
python3 /home/puzik/almquist_legal_rag_test_suite.py
```

---

## 📊 Monitoring Commands

```bash
# Check crawler status
screen -ls
ps aux | grep almquist

# Database statistics
sqlite3 /home/puzik/almquist_legal_sources.db <<EOF
SELECT
  court_level,
  COUNT(*) as total,
  SUM(CASE WHEN added_to_rag=1 THEN 1 ELSE 0 END) as in_rag
FROM court_decisions
GROUP BY court_level
ORDER BY total DESC;
EOF

# Disk usage
df -h /

# Resource status
python3 /home/puzik/almquist_resource_monitor.py

# Crawler logs
tail -f /tmp/ns_supreme_crawler.log
tail -f /tmp/justice_all_crawler.log
```

---

## 🛑 Manual Control

### Stop Crawlers
```bash
# Stop NS crawler
screen -S ns_supreme -X quit

# Stop Justice API crawler
screen -S justice_all -X quit

# Stop all
pkill -f "almquist_legal"
```

### Resume Crawlers
```bash
# Start NS crawler
screen -dmS ns_supreme bash -c \
  "python3 almquist_legal_court_decisions_crawler.py 2>&1 | tee /tmp/ns_supreme_crawler.log"

# Start Justice API crawler
screen -dmS justice_all bash -c \
  "python3 almquist_justice_api_crawler.py 2>&1 | tee /tmp/justice_all_crawler.log"
```

---

## 🔮 Future Enhancements

### Short-term
- [ ] Download full text for all decisions (via detail endpoints)
- [ ] Implement incremental updates (daily cron)
- [ ] Add decision quality scoring
- [ ] Web dashboard for monitoring

### Long-term
- [ ] Real-time notification on new decisions
- [ ] Automatic categorization by legal area
- [ ] Citation network analysis
- [ ] Multi-language support (Slovak, EU courts)

---

## 🚨 Troubleshooting

### Crawler Not Running
```bash
# Check if process exists
ps aux | grep almquist

# Check screen sessions
screen -ls

# Check logs
tail -100 /tmp/ns_supreme_crawler.log
tail -100 /tmp/justice_all_crawler.log
```

### Database Locked
```bash
# Check if other processes are using DB
lsof | grep almquist_legal_sources.db

# Kill if needed
pkill -9 -f "almquist_legal"
```

### Resource Limits Hit
```bash
# Check current usage
python3 /home/puzik/almquist_resource_monitor.py

# Free up disk space
df -h
rm -rf /tmp/old_logs

# Kill resource-heavy processes
top
```

---

## 📞 Support

**Logs:** `/tmp/ns_supreme_crawler.log`, `/tmp/justice_all_crawler.log`
**Database:** `/home/puzik/almquist_legal_sources.db`
**RAG Data:** `/home/puzik/almquist_legal_rag/`

---

**🚀 PRODUCTION READY - Autonomous Legal Crawl System**

**ALL Czech Courts | ~546,000+ Decisions | Resource Monitored | Auto-stop Protected**
