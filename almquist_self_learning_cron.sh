#!/bin/bash
#
# ALMQUIST RAG - Self-Learning Cron Job
# Spouští self-learning cycle každé pondělí v 2:00
#

# Nastavení prostředí
export PATH=/home/puzik/miniconda3/bin:/usr/local/bin:/usr/bin:/bin
export PYTHONPATH=/home/puzik

# Log file
CRON_LOG="/home/puzik/almquist_self_learning_cron.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "════════════════════════════════════════════════════════" >> "$CRON_LOG"
echo "[$DATE] ALMQUIST Self-Learning Cycle START" >> "$CRON_LOG"
echo "════════════════════════════════════════════════════════" >> "$CRON_LOG"

# Přejít do domovského adresáře
cd /home/puzik || exit 1

# Spustit master skript
python3 /home/puzik/almquist_self_learning_master.py >> "$CRON_LOG" 2>&1
EXIT_CODE=$?

DATE_END=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$DATE_END] Self-Learning Cycle dokončen (exit code: $EXIT_CODE)" >> "$CRON_LOG"
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
