# 🚀 Chronos Cleanup: Automated Linux System Maintenance Utility

This solution integrates a **Bash script (`system_cleaner.sh`)** with the **Cron scheduler** for autonomous system maintenance on Debian/Ubuntu environments.  
The utility quantifies recovered disk space and delivers a real-time summary notification via a Telegram bot, ensuring verifiable, continuous system hygiene with no manual supervision required.

---

## ✨ Features: System Maintenance Protocol Summary

The script executes critical routines to mitigate clutter and reclaim storage capacity.

### 🧹 System Cleanup
#### **APT Cache Management**
Purges downloaded packages and eliminates deprecated files (`apt clean`, `autoclean`, `autoremove`) to manage `/var/cache/apt/archives` volume.

#### **Journal Log Truncation**
Enforces a log retention policy using `journalctl`, preserving records for the last 7 days or capping total log size at 100MB.

#### **Snap Revision Decommissioning**
Systematically uninstalls superseded, disabled Snap revisions to recover occupied disk space.

#### **Thumbnail Cache Purge**
Clears the user's local thumbnail cache (`~/.cache/thumbnails/`).

---

### 📊 Reporting
Disk usage is quantified before and after execution, generating a precise measure of freed space (KB, MB, or GB) for empirical verification.

### 📩 Notification
The `send_telegram` function transmits the summary report immediately upon job completion, providing instant, auditable confirmation of the maintenance status.

---

## 💻 `system_cleaner.sh` Script

```bash
#!/bin/bash
# ============================================================
# 🧹 Linux System Cleaner Script with Telegram Notification
# ============================================================

LOG_FILE="/var/log/system_cleaner.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
# NOTE: Replace these with your actual BOT_TOKEN and CHAT_ID
BOT_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"

send_telegram() {
    MESSAGE="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"         -d chat_id="${CHAT_ID}"         -d text="${MESSAGE}" >/dev/null 2>&1
}

echo "=== System cleanup started at $DATE ===" | tee -a "$LOG_FILE"

BEFORE=$(df --output=used / | tail -1)
BEFORE_H=$(df -h --output=used / | tail -1)

echo "[+] Cleaning APT cache..." | tee -a "$LOG_FILE"
sudo apt clean -y >> "$LOG_FILE" 2>&1
sudo apt autoclean -y >> "$LOG_FILE" 2>&1
sudo apt autoremove -y >> "$LOG_FILE" 2>&1

echo "[+] Cleaning old logs..." | tee -a "$LOG_FILE"
sudo journalctl --vacuum-time=7d >> "$LOG_FILE" 2>&1
sudo journalctl --vacuum-size=100M >> "$LOG_FILE" 2>&1

echo "[+] Removing old Snap revisions..." | tee -a "$LOG_FILE"
sudo snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
    sudo snap remove "$snapname" --revision="$revision" >> "$LOG_FILE" 2>&1
done

echo "[+] Clearing user thumbnail cache..." | tee -a "$LOG_FILE"
rm -rf ~/.cache/thumbnails/* >> "$LOG_FILE" 2>&1

echo "[+] Final autoremove purge..." | tee -a "$LOG_FILE"
sudo apt autoremove --purge -y >> "$LOG_FILE" 2>&1

AFTER=$(df --output=used / | tail -1)
AFTER_H=$(df -h --output=used / | tail -1)

FREED=$((BEFORE - AFTER))

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

send_telegram "$SUMMARY"
```

---

## 🛠️ Setup & Scheduling: Operational Deployment

### 1️⃣ Execution Setup

**Grant execution privileges:**
```bash
chmod +x system_cleaner.sh
```

**Validation Testing:**
```bash
sudo ./system_cleaner.sh
```
> ✅ Verify that the script performs cleanup correctly before scheduling.

**Create a symbolic link for global access:**
```bash
sudo ln -s /path/to/your/system_cleaner.sh /usr/local/bin/system_cleaner
```
> Symbolic link allows Cron or other users to execute the script directly as `system_cleaner`.

---

### 2️⃣ Cron Job Scheduling

Edit the root user’s crontab:
```bash
sudo crontab -e
```

Add the following line to schedule cleanup **weekly on Friday at midnight**:
```bash
0 0 * * 5 /usr/local/bin/system_cleaner >> /var/log/system_cleaner_cron.log 2>&1
```

---

## 📞 Telegram Monitoring: Observability and Audit

Configuration of the `BOT_TOKEN` and `CHAT_ID` variables inside the script is mandatory for successful Telegram message delivery.  
This ensures continuous observability and audit logging of your maintenance jobs.

---

### 📷 Example Screenshots to Include
- Script Execution Result
- Symbolic Link Verification
- Cron Command and Entry
- Telegram Notification Message Example

---

© 2025 – Chronos Cleanup Utility | Developed for Continuous Linux Maintenance | By Eng. Abdalrahman Ashraf
