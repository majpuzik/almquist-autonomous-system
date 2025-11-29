#!/bin/bash
#
# ALMQUIST RAG - Cron Job Wrapper
# Spouští automatickou aktualizaci RAG databáze
# Určeno pro noční spuštění (3:00 AM)
#

# Nastavení prostředí
export PATH=/home/puzik/miniconda3/bin:/usr/local/bin:/usr/bin:/bin
export PYTHONPATH=/home/puzik

# Log file pro cron výstup
CRON_LOG="/home/puzik/almquist_rag_cron.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "════════════════════════════════════════════════════════" >> "$CRON_LOG"
echo "[$DATE] ALMQUIST RAG - Automatická aktualizace START" >> "$CRON_LOG"
echo "════════════════════════════════════════════════════════" >> "$CRON_LOG"

# Přejít do domovského adresáře
cd /home/puzik || exit 1

# Spustit updater
python3 /home/puzik/almquist_rag_updater.py >> "$CRON_LOG" 2>&1
EXIT_CODE=$?

DATE_END=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$DATE_END] ALMQUIST RAG - Aktualizace dokončena (exit code: $EXIT_CODE)" >> "$CRON_LOG"
echo "" >> "$CRON_LOG"

# Rotace logu (max 100000 řádků = cca 30 dní)
if [ -f "$CRON_LOG" ]; then
    LINE_COUNT=$(wc -l < "$CRON_LOG")
    if [ "$LINE_COUNT" -gt 100000 ]; then
        tail -n 50000 "$CRON_LOG" > "$CRON_LOG.tmp"
        mv "$CRON_LOG.tmp" "$CRON_LOG"
    fi
fi

exit $EXIT_CODE
