🚀 Chronos Cleanup: Automated Linux System Maintenance UtilityThis solution integrates a Bash script (system_cleaner.sh) with the Cron scheduler for autonomous system maintenance on Debian/Ubuntu environments. The utility quantifies recovered disk space and delivers a real-time summary notification via a Telegram bot, ensuring verifiable, continuous system hygiene with no manual supervision required.✨ Features: System Maintenance Protocol SummaryThe script executes critical routines to mitigate clutter and reclaim storage capacity:System Cleanup:APT Cache Management: Purges downloaded packages and eliminates deprecated files (apt clean, autoclean, autoremove) to manage /var/cache/apt/archives volume.Journal Log Truncation: Enforces a log retention policy using journalctl, preserving records for the last 7 days or capping the total log size at 100MB.Snap Revision Decommissioning: Systematically uninstalls superseded, disabled Snap revisions to recover occupied disk space.Thumbnail Cache Purge: Clears the user's local thumbnail cache (~/.cache/thumbnails/).Reporting: Disk usage is quantified before and after execution, generating a precise measure of freed space (KB, MB, or GB) for empirical verification.Notification: The send_telegram function transmits the summary report immediately upon job completion, providing instant, auditable confirmation of the maintenance status.💻 system_cleaner.sh Script#!/bin/bash
# ============================================================
# 🧹 Linux System Cleaner Script with Telegram Notification
# ============================================================

LOG_FILE="/var/log/system_cleaner.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
# NOTE: Replace these with your actual BOT_TOKEN and CHAT_ID
BOT_TOKEN="8586733810:AAHXT7hAnGaW1cLVUXjsm6IQOzoLU_9qvEI" 
CHAT_ID="7609044409"

send_telegram() {
    MESSAGE="$1"
    # Use 'curl' to send the message via the Telegram Bot API
    curl -s -X POST "[https://api.telegram.org/bot$](https://api.telegram.org/bot$){BOT_TOKEN}/sendMessage" \
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
# Keep only logs from the last 7 days and limit total size to 100M
sudo journalctl --vacuum-time=7d >> "$LOG_FILE" 2>&1
sudo journalctl --vacuum-size=100M >> "$LOG_FILE" 2>&1

# 3️⃣ Clean old snap revisions
echo "[+] Removing old Snap revisions..." | tee -a "$LOG_FILE"
# This loop finds and removes all 'disabled' (old) snap revisions
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


🛠️ Setup & Scheduling: Operational Deployment1. Execution SetupPreparation: Grant execution privileges (chmod +x system_cleaner.sh).Validation Testing: Execute the script with sudo ./system_cleaner.sh. !(uploaded:script_run.png-f4d8d390-ab10-4622-ad96-bbfe3826a145)Global Access Establishment: Create a symbolic link in the system's PATH for convenient Cron execution:sudo ln -s /path/to/your/system_cleaner.sh /usr/local/bin/system_cleaner
!(uploaded:symbolic_link.png-ae1a8589-5cc9-42d3-b837-fef88bc44411)2. Cron Job SchedulingSchedule the privileged job within the root user's crontab (sudo crontab -e). !(uploaded:cron_command.png-499b94f2-f38c-42b4-a776-0c567cb7f237)Insert the job entry (e.g., weekly on Friday at 00:00) and redirect I/O for comprehensive logging:0 0 * * 5 /usr/local/bin/system_cleaner >> /var/log/system_cleaner_cron.log 2>&1
!(uploaded:cron_setting.png-50ad5555-9e20-4632-81a4-b09829f851ea)📞 Telegram Monitoring: Observability and AuditConfiguration of the BOT_TOKEN and CHAT_ID variables is required for successful transmission of the completion summary, ensuring continuous operational observability.!(uploaded:Telegram_cron_notify.jpg-11055386-cf9d-4bc4-b011-daa932d3cb8f)
