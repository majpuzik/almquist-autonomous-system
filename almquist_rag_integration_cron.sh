#!/bin/bash
#
# ALMQUIST RAG INTEGRATION - Cron Job
# Spouští RAG integration po crawleru (daily at 5:00 AM)
# Přidává high-quality chunks z crawleru do RAG systému
#

# Nastavení prostředí
export PATH=/home/puzik/miniconda3/bin:/usr/local/bin:/usr/bin:/bin
export PYTHONPATH=/home/puzik

# Log file
CRON_LOG="/home/puzik/almquist_rag_integration_cron.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "════════════════════════════════════════════════════════" >> "$CRON_LOG"
echo "[$DATE] ALMQUIST RAG Integration START" >> "$CRON_LOG"
echo "════════════════════════════════════════════════════════" >> "$CRON_LOG"

# Přejít do domovského adresáře
cd /home/puzik || exit 1

# Spustit RAG integration
python3 /home/puzik/almquist_crawler_rag_integration.py >> "$CRON_LOG" 2>&1
EXIT_CODE=$?

DATE_END=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$DATE_END] RAG Integration dokončen (exit code: $EXIT_CODE)" >> "$CRON_LOG"
echo "" >> "$CRON_LOG"

# Rotace logu
if [ -f "$CRON_LOG" ]; then
    LINE_COUNT=$(wc -l < "$CRON_LOG")
    if [ "$LINE_COUNT" -gt 50000 ]; then
        tail -n 25000 "$CRON_LOG" > "$CRON_LOG.tmp"
        mv "$CRON_LOG.tmp" "$CRON_LOG"
    fi
fi

exit $EXIT_CODE
