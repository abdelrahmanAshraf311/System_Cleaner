#!/bin/bash
# ============================================================
# 🧹 Linux System Cleaner Script with Telegram Notification
# ============================================================

LOG_FILE="/var/log/system_cleaner.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
BOT_TOKEN="8586733810:AAHXT7hAnGaW1cLVUXjsm6IQOzoLU_9qvEI"
CHAT_ID="7609044409"

send_telegram() {
    MESSAGE="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${MESSAGE}" >/dev/null 2>&1
}

echo "=== System cleanup started at $DATE ===" | tee -a "$LOG_FILE"

# Record disk usage before cleanup
BEFORE=$(df --output=used / | tail -1)
BEFORE_H=$(df -h --output=used / | tail -1)

# 1️⃣ Clean APT cache
echo "[+] Cleaning APT cache..." | tee -a "$LOG_FILE"
sudo apt clean -y >> "$LOG_FILE" 2>&1
sudo apt autoclean -y >> "$LOG_FILE" 2>&1
sudo apt autoremove -y >> "$LOG_FILE" 2>&1

# 2️⃣ Remove old logs
echo "[+] Cleaning old logs..." | tee -a "$LOG_FILE"
sudo journalctl --vacuum-time=7d >> "$LOG_FILE" 2>&1
sudo journalctl --vacuum-size=100M >> "$LOG_FILE" 2>&1

# 3️⃣ Clean old snap revisions
echo "[+] Removing old Snap revisions..." | tee -a "$LOG_FILE"
sudo snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
    sudo snap remove "$snapname" --revision="$revision" >> "$LOG_FILE" 2>&1
done

# 4️⃣ Clear thumbnail cache
echo "[+] Clearing user thumbnail cache..." | tee -a "$LOG_FILE"
rm -rf ~/.cache/thumbnails/* >> "$LOG_FILE" 2>&1

# 5️⃣ Final cleanup
echo "[+] Final autoremove purge..." | tee -a "$LOG_FILE"
sudo apt autoremove --purge -y >> "$LOG_FILE" 2>&1

# Record disk usage after cleanup
AFTER=$(df --output=used / | tail -1)
AFTER_H=$(df -h --output=used / | tail -1)

# Calculate freed space (in KB)
FREED=$((BEFORE - AFTER))

# Convert to human readable (approximate MB/GB)
if [ "$FREED" -lt 1024 ]; then
    FREED_H="${FREED}K"
elif [ "$FREED" -lt 1048576 ]; then
    FREED_H="$(awk "BEGIN {printf \"%.2f MB\", $FREED/1024}")"
else
    FREED_H="$(awk "BEGIN {printf \"%.2f GB\", $FREED/1048576}")"
fi

END_DATE=$(date '+%Y-%m-%d %H:%M:%S')
SUMMARY="🧹 System cleanup completed on $END_DATE
Freed space: $FREED_H
Used before: $BEFORE_H
Used after:  $AFTER_H"

echo "=== Cleanup completed at $END_DATE ===" | tee -a "$LOG_FILE"
echo "$SUMMARY" | tee -a "$LOG_FILE"

# Send Telegram message
send_telegram "$SUMMARY"

