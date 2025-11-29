# ALMQUIST Legal RAG - Advokátní Poradenství

**Specializovaný RAG systém pro české právní prostředí**

---

## 🎯 Cíl

Vytvořit autonomní RAG systém obsahující:
1. **Veškeré české zákony** (trestní, občanské, správní, atd.)
2. **Rozsudky všech soudů** (Nejvyšší, Ústavní, Nejvyšší správní, krajské, okresní)
3. **Automatické updaty** nových zákonů a rozsudků
4. **Strukturovaná kategorizace** pro snadné vyhledávání

---

## 🏗️ Architektura

```
┌──────────────────────────────────────────────────────────────┐
│  PRÁVNÍ ZDROJE                                               │
├──────────────────────────────────────────────────────────────┤
│  1. ZÁKONY                                                   │
│     • zakonyprolidi.cz API (JSON/XML)                       │
│     • Sbírka zákonů ČR (aktuální + historické verze)        │
│                                                              │
│  2. ROZSUDKY                                                 │
│     • Nejvyšší soud: sbirka.nsoud.cz                        │
│     • Ústavní soud: nalus.usoud.cz                          │
│     • Nejvyšší správní soud: vyhledavac.nssoud.cz           │
│     • Krajské/okresní soudy: justice.cz                     │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  SPECIALIZED LEGAL CRAWLER                                   │
├──────────────────────────────────────────────────────────────┤
│  • API Integration (zakonyprolidi.cz)                       │
│  • Web Scraping (sbirka.nsoud.cz, nalus.usoud.cz)          │
│  • Content Extraction & Parsing                             │
│  • Legal Document Categorization                            │
│  • Change Detection                                          │
│                                                              │
│  Database: almquist_legal_sources.db                        │
│  Tables:                                                     │
│    - laws (zákony)                                          │
│    - court_decisions (rozsudky)                             │
│    - crawl_history                                          │
│    - content_changes                                        │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  LEGAL RAG SYSTEM                                            │
├──────────────────────────────────────────────────────────────┤
│  Model: paraphrase-multilingual-MiniLM-L12-v2              │
│  Embedding: 384D vectors                                     │
│  Index: FAISS IndexFlatIP                                    │
│                                                              │
│  Metadata Structure:                                         │
│    - document_type: [law, court_decision]                   │
│    - law_category: [civil, criminal, administrative, ...]   │
│    - court_level: [supreme, constitutional, administrative] │
│    - decision_type: [nalez, usneseni, rozsudek]            │
│    - legal_area: [trestni, obcanske, spravni, ...]         │
│    - relevance: [case_number, affected_laws, keywords]      │
│                                                              │
│  Directory: /home/puzik/almquist_legal_rag/                │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  AUTO-UPDATE SYSTEM                                          │
├──────────────────────────────────────────────────────────────┤
│  Daily:   Check for new court decisions (02:00)             │
│  Weekly:  Check for new/amended laws (Sunday 01:00)         │
│  Monthly: Full resync & quality check                        │
└──────────────────────────────────────────────────────────────┘
```

---

## 📊 Databázová Struktura

### `almquist_legal_sources.db`

#### 1. Table: `laws`
```sql
CREATE TABLE laws (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    law_number TEXT NOT NULL,              -- "89/2012 Sb."
    law_name TEXT NOT NULL,                -- "Občanský zákoník"
    law_type TEXT,                         -- "zakon", "vyhlaska", "narizeni"
    category TEXT,                         -- "civil", "criminal", "administrative"
    full_text TEXT,                        -- Plný text zákona
    effective_from DATE,                   -- Datum účinnosti
    effective_to DATE,                     -- NULL pokud platný
    last_amendment TEXT,                   -- Poslední novela
    source_url TEXT,                       -- URL zdroje
    added_to_rag INTEGER DEFAULT 0,        -- 0=pending, 1=in RAG
    rag_chunk_ids TEXT,                    -- JSON array chunk IDs
    crawled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
```

#### 2. Table: `court_decisions`
```sql
CREATE TABLE court_decisions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    case_number TEXT NOT NULL,             -- "25 Cdo 1234/2024"
    court_level TEXT NOT NULL,             -- "supreme", "constitutional", "administrative"
    court_name TEXT,                       -- "Nejvyšší soud"
    decision_type TEXT,                    -- "rozsudek", "nalez", "usneseni"
    decision_date DATE,                    -- Datum rozhodnutí
    ecli TEXT,                             -- ECLI identifikátor
    legal_area TEXT,                       -- "trestni", "obcanske", "spravni"
    affected_laws TEXT,                    -- JSON array ["89/2012 § 1000", ...]
    keywords TEXT,                         -- JSON array ["dědictví", "copyright", ...]
    summary TEXT,                          -- Krátké shrnutí
    full_text TEXT,                        -- Plný text rozsudku
    source_url TEXT,                       -- URL zdroje
    added_to_rag INTEGER DEFAULT 0,        -- 0=pending, 1=in RAG
    rag_chunk_ids TEXT,                    -- JSON array chunk IDs
    crawled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
```

#### 3. Table: `crawl_history`
```sql
CREATE TABLE crawl_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source TEXT NOT NULL,                  -- "zakonyprolidi_api", "nsoud_sbirka", ...
    source_type TEXT NOT NULL,             -- "law", "court_decision"
    crawled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT,                           -- "success", "failed"
    items_found INTEGER DEFAULT 0,
    items_added INTEGER DEFAULT 0,
    error_message TEXT
);
```

#### 4. Table: `content_changes`
```sql
CREATE TABLE content_changes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_type TEXT NOT NULL,           -- "law", "court_decision"
    document_id INTEGER NOT NULL,          -- FK to laws.id or court_decisions.id
    change_type TEXT,                      -- "new", "amendment", "repeal"
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_hash TEXT,
    new_hash TEXT,
    significance TEXT                      -- "major", "minor"
);
```

---

## 🔍 Kategorizace Dokumentů

### Typy Zákonů (law_category)
- `civil` - Občanské právo (89/2012 Sb., 90/2012 Sb.)
- `criminal` - Trestní právo (40/2009 Sb., 141/1961 Sb.)
- `administrative` - Správní právo (500/2004 Sb.)
- `commercial` - Obchodní právo
- `labor` - Pracovní právo (262/2006 Sb.)
- `tax` - Daňové právo
- `constitutional` - Ústavní právo (1/1993 Sb.)

### Úrovně Soudů (court_level)
- `supreme` - Nejvyšší soud (NS)
- `constitutional` - Ústavní soud (ÚS)
- `administrative` - Nejvyšší správní soud (NSS)
- `regional` - Krajské soudy
- `district` - Okresní soudy

### Typy Rozhodnutí (decision_type)
- `rozsudek` - Rozsudek (NS, NSS, krajské/okresní soudy)
- `nalez` - Nález (ÚS)
- `usneseni` - Usnesení (všechny soudy)
- `stanovisko` - Stanovisko (NS, ÚS)

### Právní Oblasti (legal_area)
- `obcanske` - Občanské právo
- `trestni` - Trestní právo
- `spravni` - Správní právo
- `obchodni` - Obchodní právo
- `pracovni` - Pracovní právo
- `danove` - Daňové právo

---

## 🤖 Crawler Strategie

### 1. Zákony (zakonyprolidi.cz API)

**API Přístup:**
- Endpoint: API zakonyprolidi.cz (vyžaduje apikey)
- Formát: JSON/XML
- Akce: Požádat o partnerský přístup ([email protected])

**Alternativa bez API:**
- Web scraping: https://www.zakonyprolidi.cz/cs/aktualni
- Parsování HTML struktury
- Stahování jednotlivých zákonů

**Prioritní Zákony:**
1. Občanský zákoník (89/2012 Sb.)
2. Zákon o obchodních korporacích (90/2012 Sb.)
3. Trestní zákoník (40/2009 Sb.)
4. Trestní řád (141/1961 Sb.)
5. Občanský soudní řád (99/1963 Sb.)
6. Správní řád (500/2004 Sb.)
7. Zákoník práce (262/2006 Sb.)
8. Ústava ČR (1/1993 Sb.)
9. Listina základních práv (2/1993 Sb.)
10. Daňové zákony (586/1992 Sb., 235/2004 Sb., ...)

### 2. Rozsudky Nejvyššího Soudu

**Zdroj:** https://sbirka.nsoud.cz
**Metoda:** Web scraping
**Struktura:**
- Pokročilé vyhledávání
- ECLI identifikátory
- Stahování jednotlivých rozhodnutí
- Parsování datum, spisová značka, keywords

**Crawl Strategie:**
- Start: Nejnovější rozhodnutí
- Postupná integrace starších (2024 → 2023 → ...)
- Sledování nových rozhodnutí (daily check)

### 3. Rozsudky Ústavního Soudu

**Zdroj:** https://nalus.usoud.cz
**Metoda:** Web scraping
**Features:**
- Vyhledávání podle data, typu rozhodnutí
- Filtrování podle právní oblasti
- Exportní možnosti (pokud existují)

### 4. Rozsudky Nejvyššího Správního Soudu

**Zdroj:** https://vyhledavac.nssoud.cz + https://sbirka.nssoud.cz
**Metoda:** Web scraping
**Rozsah:** 1997-2025

---

## 📦 RAG Metadata Struktura

### Příklad: Zákon

```json
{
  "chunk_id": "law_89_2012_section_1000",
  "document_type": "law",
  "law_number": "89/2012 Sb.",
  "law_name": "Občanský zákoník",
  "section": "§ 1000",
  "category": "civil",
  "effective_from": "2014-01-01",
  "effective_to": null,
  "source_url": "https://www.zakonyprolidi.cz/cs/2012-89#p1000",
  "relevance_score": 1.0,
  "added_at": "2025-11-29T22:00:00"
}
```

### Příklad: Rozsudek

```json
{
  "chunk_id": "decision_25_cdo_1234_2024",
  "document_type": "court_decision",
  "case_number": "25 Cdo 1234/2024",
  "court_level": "supreme",
  "court_name": "Nejvyšší soud",
  "decision_type": "rozsudek",
  "decision_date": "2024-11-15",
  "ecli": "ECLI:CZ:NS:2024:25.CDO.1234.2024.1",
  "legal_area": "obcanske",
  "affected_laws": ["89/2012 § 1000", "99/1963 § 157"],
  "keywords": ["dědictví", "věcné břemeno"],
  "summary": "Rozsudek o výkladu § 1000 občanského zákoníku...",
  "source_url": "https://sbirka.nsoud.cz/...",
  "relevance_score": 0.95,
  "added_at": "2025-11-29T22:00:00"
}
```

---

## ⏰ Update Schedule

```bash
# Sunday 01:00 - Check for new/amended laws
0 1 * * 0  /home/puzik/almquist_legal_laws_cron.sh

# Daily 02:00 - Check for new court decisions (all courts)
0 2 * * *  /home/puzik/almquist_legal_decisions_cron.sh

# Daily 03:00 - Legal RAG Integration
0 3 * * *  /home/puzik/almquist_legal_rag_integration_cron.sh

# 1st day of month 00:00 - Full resync & quality check
0 0 1 * *  /home/puzik/almquist_legal_full_resync_cron.sh
```

---

## 🚀 Implementation Plan

### Phase 1: Core Infrastructure (Week 1)
- [ ] Setup legal sources database (`almquist_legal_sources.db`)
- [ ] Create base crawler framework
- [ ] Setup legal RAG directory structure
- [ ] Request zakonyprolidi.cz API access

### Phase 2: Laws Integration (Week 2)
- [ ] Implement zakonyprolidi.cz API client
- [ ] Crawl prioritní zákony (top 10)
- [ ] Parse & structure legal texts
- [ ] Generate embeddings
- [ ] Add to legal RAG

### Phase 3: Court Decisions - Nejvyšší Soud (Week 3)
- [ ] Implement sbirka.nsoud.cz scraper
- [ ] Parse court decisions (2024 decisions first)
- [ ] Extract metadata (case number, ECLI, keywords)
- [ ] Add to legal RAG

### Phase 4: Court Decisions - Ústavní & NSS (Week 4)
- [ ] Implement nalus.usoud.cz scraper
- [ ] Implement vyhledavac.nssoud.cz scraper
- [ ] Integrate all court levels
- [ ] Complete legal RAG

### Phase 5: Automation & Monitoring (Week 5)
- [ ] Setup cron jobs for auto-updates
- [ ] Implement change detection
- [ ] Create monitoring dashboard
- [ ] CDB logging integration

---

## 📈 Expected Results

### Coverage
- **Zákony:** 500+ hlavních zákonů a vyhlášek
- **Rozsudky NS:** 10,000+ rozhodnutí (2020-2025)
- **Rozsudky ÚS:** 5,000+ nálezů a usnesení
- **Rozsudky NSS:** 8,000+ rozhodnutí (2020-2025)

### RAG Size
- **Total chunks:** ~200,000-500,000
- **Embeddings:** 384D vectors
- **Storage:** ~5-10 GB (embeddings + metadata)

### Update Frequency
- **Zákony:** Weekly (Sunday)
- **Rozsudky:** Daily (new decisions)
- **Full resync:** Monthly

---

## 🔧 Tech Stack

### Core
- Python 3.10+
- SQLite3 (almquist_legal_sources.db)
- sentence-transformers (paraphrase-multilingual-MiniLM-L12-v2)
- FAISS (IndexFlatIP)

### Web Crawling
- requests / httpx
- BeautifulSoup4 / lxml
- Selenium (if needed for JavaScript-heavy pages)

### NLP & Processing
- spaCy (Czech language model)
- Legal text parsing libraries
- PDF extraction (PyPDF2, pdfplumber)

### Monitoring
- CDB logging (maj-almquist-log)
- Custom dashboard

---

## 📄 Files Structure

```
/home/puzik/almquist-legal-rag/
├── almquist_legal_crawler.py         # Main crawler
├── almquist_legal_laws_crawler.py    # Laws-specific crawler
├── almquist_legal_decisions_crawler.py # Court decisions crawler
├── almquist_legal_rag_integration.py # RAG integration
├── almquist_legal_sources.db         # SQLite database
├── embeddings/
│   ├── faiss_index.bin
│   ├── embeddings.npy
│   └── metadata.json
├── logs/
│   ├── crawler.log
│   └── rag_integration.log
└── config/
    ├── sources.json                  # Source definitions
    └── api_keys.json                 # API credentials
```

---

## ✅ Success Criteria

1. **Completeness:** All major Czech laws in RAG
2. **Recency:** New court decisions added within 24h
3. **Quality:** High relevance scores (≥0.8 for legal docs)
4. **Performance:** Query response < 2s
5. **Reliability:** 99%+ uptime for auto-updates

---

**Next Steps:**
1. Request zakonyprolidi.cz API access
2. Implement base legal crawler
3. Create legal RAG database schema
4. Start with top 10 priority laws

---

**Status:** Architecture Design Complete ✅
**Date:** 2025-11-29
