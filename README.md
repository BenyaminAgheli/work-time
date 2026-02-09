### Work-Time Tracker

A lightweight Bash utility that transforms Linux system boot logs into a visual work-time report. It tracks when you started your machine (IN) and when you shut it down (OUT), calculating daily totals and displaying an ASCII progress bar.
Preview
Plaintext
```
+------------+----------+----------+-------+--------------------------------+
|    DATE    |    IN    |    OUT   | HOURS |            VISUAL CHART        |
+------------+----------+----------+-------+--------------------------------+
| 2026/02/09 | 08:30:00 | 17:00:00 | 8.50  | #################              |
+------------+----------+----------+-------+--------------------------------+
```
### How it Works
**The Script:** Parses journalctl --list-boots to extract the first and last log entry for every boot cycle recorded by the system.

**Systemd Integration:** Uses a "oneshot" service that triggers on shutdown or reboot. This ensures the final timestamp is captured accurately in the system journal before the OS halts.

**Calculation:** Computes the difference between boot-up and shutdown, converting seconds into decimal hours and a visual ASCII bar chart where each # represents 30 minutes of activity.

### Installation
**1. Deploy the Script**

Copy the script:
```
cp work-time.sh /usr/local/bin/work-time.sh
chmod +x /usr/local/bin/work-time.sh
```
**2. Setup the Shutdown Tracker**

Create the systemd service file:
```
nano /etc/systemd/system/work-time.service
```
Paste the following configuration:
```
Ini, TOML

[Unit]
Description=Register work-out time at shutdown
DefaultDependencies=no
Conflicts=reboot.target halt.target poweroff.target
Before=reboot.target halt.target poweroff.target

[Service]
Type=oneshot
ExecStart=/bin/true
ExecStop=/usr/local/bin/work-time.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```
**3. Enable the ServicE**
```
systemctl daemon-reload
systemctl enable work-time.service
systemctl start work-time.service
```
### Usage

Run the script from the terminal to view your work-time history:
```
./work-time.sh
```
### Requirements
**Systemd:** Required for access to journalctl and service management.

**awk:** Used for data parsing and arithmetic calculations.

**jdate:** Used in the script for specific date formatting. Ensure this utility is installed on your system.
