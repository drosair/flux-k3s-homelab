# 🍓 Raspberry Pi Kubernetes Control Plane Setup

This guide walks through setting up a Raspberry Pi running Raspberry Pi OS (Lite) as a Kubernetes control plane node using `k3s`. It includes embedded `etcd` storage, NFS-based backup, live log monitoring, voltage status checks, and PagerDuty alerting. It is designed for a home-lab or small-scale HA environment and focuses on simplicity, automation, and reliability.

## ✅ Features

* Lightweight Kubernetes (`k3s`) with embedded `etcd`
* Automated etcd backups to NAS using NFS
* Secure `kubectl` access and permission fixes
* Realtime `k3s` log monitoring
* Voltage monitoring with `vcgencmd`
* PagerDuty alert integration on failure or undervoltage
* Guidance for graceful shutdown and troubleshooting

---

## 🚀 Step 1: Install `k3s` (with etcd and fixed IP)

Install `k3s` using the official script with a fixed IP (to prevent etcd conflicts), group-readable kubeconfig, and initial cluster setup:

```bash
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="server \
    --node-ip=192.168.0.214 \
    --advertise-address=192.168.0.214 \
    --cluster-init \
    --write-kubeconfig-mode 0640 \
    --write-kubeconfig-group admin" \
  sh -
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="server --cluster-init --write-kubeconfig-mode 0640 --write-kubeconfig-group admin" \
  sh -
```

This:

* Installs `k3s` with embedded `etcd`
* Starts the control plane
* Creates a kubeconfig at `/etc/rancher/k3s/k3s.yaml` readable by the `admin` group

### 🔐 Verify and Export kubeconfig

```bash
ls -l /etc/rancher/k3s/k3s.yaml
```

Expected output:

```
-rw-r----- 1 root admin 2961 ... /etc/rancher/k3s/k3s.yaml
```

Then export it for the session:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

### 🚦 Verify cluster health

```bash
kubectl get nodes
kubectl get pods -A
```

---

## 🪵 Step 2: Monitor `k3s` Logs

To watch logs in real time:

```bash
sudo journalctl -u k3s -f
```

Or to see the last 100 lines:

```bash
sudo journalctl -u k3s -n 100 --no-pager
```

---

## 📁 Step 3: Mount NASBOX for etcd backups

### 1. Install NFS support

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install nfs-common -y
```

### 2. Create mount point

```bash
sudo mkdir -p /mnt/nasbox/etcd
```

### 3. Add NFS entry to `/etc/fstab`

```bash
sudo nano /etc/fstab
```

Add:

```
192.168.0.2:/share/Container/etcd /mnt/nasbox/etcd nfs defaults,_netdev 0 0
```

### 4. Mount immediately

```bash
sudo mount -a
df -h | grep nasbox
```

---

## 📦 Step 4: Install `etcdctl`

```bash
ETCD_VER=v3.5.21
wget https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-arm64.tar.gz
tar xzvf etcd-${ETCD_VER}-linux-arm64.tar.gz
sudo mv etcd-${ETCD_VER}-linux-arm64/etcdctl /usr/local/bin/
```

Verify:

```bash
etcdctl version
```

---

## ⏰ Step 5: Automate etcd Backups via systemd

Create the backup script:

```bash
sudo nano /usr/local/bin/etcd-backup.sh
```

Paste:

```bash
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/mnt/nasbox/etcd"
SNAPSHOT_NAME="etcd-snapshot-$TIMESTAMP.db"
VCGENCMD_OUTPUT=$(vcgencmd get_throttled)

/usr/local/bin/etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt \
  --cert=/var/lib/rancher/k3s/server/tls/etcd/server-client.crt \
  --key=/var/lib/rancher/k3s/server/tls/etcd/server-client.key \
  snapshot save "$BACKUP_DIR/$SNAPSHOT_NAME"

if [ $? -ne 0 ] || [[ "$VCGENCMD_OUTPUT" != "throttled=0x0" ]]; then
  curl -X POST https://events.pagerduty.com/v2/enqueue \
    -H "Content-Type: application/json" \
    -d '{
      "routing_key": "YOUR_ROUTING_KEY_HERE",
      "event_action": "trigger",
      "payload": {
        "summary": "etcd backup failed or undervoltage detected on Pi control-plane",
        "source": "kube-pi",
        "severity": "error"
      }
    }'
fi

# Keep only 7 most recent backups
ls -1t "$BACKUP_DIR"/etcd-snapshot-*.db | tail -n +8 | xargs rm -f
```

Make executable:

```bash
sudo chmod +x /usr/local/bin/etcd-backup.sh
```

### Create the systemd units:

#### Service unit

```bash
sudo nano /etc/systemd/system/etcd-backup.service
```

```ini
[Unit]
Description=Backup etcd to NASBOX

[Service]
ExecStart=/usr/local/bin/etcd-backup.sh
```

#### Timer unit

```bash
sudo nano /etc/systemd/system/etcd-backup.timer
```

```ini
[Unit]
Description=Daily etcd backup to NASBOX

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now etcd-backup.timer
```

Check:

```bash
systemctl status etcd-backup.timer
journalctl -u etcd-backup.service
```

---

## 🔌 Step 6: Voltage Monitoring via `vcgencmd`

Install:

```bash
sudo apt install libraspberrypi-bin -y
```

Check voltage:

```bash
vcgencmd get_throttled
dmesg | grep -i voltage
```

Disable Wi-Fi (if using Ethernet-only setup):

```bash
sudo nmcli radio wifi off
```

---

## 🚨 PagerDuty Alerts (via etcd-backup.sh)

PagerDuty alerts are triggered from the backup script:

* On backup failure
* On undervoltage

Replace `YOUR_ROUTING_KEY_HERE` in the script with your real PagerDuty Events API v2 key.
Test by forcing a failure (e.g., unmount NFS and run the script).

---

## ⏹ Graceful Shutdown

To safely shut down the Pi:

```bash
sudo shutdown -h now
```

If other nodes are active:

```bash
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

Then shut down.

---

## 🧯 Troubleshooting Tips

### Permission denied on kubeconfig:

Fix:

```bash
sudo chmod 640 /etc/rancher/k3s/k3s.yaml
sudo chgrp admin /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

### `kubectl` shows “ServiceUnavailable”:

Likely means `k3s` is still starting. Monitor logs with:

```bash
sudo journalctl -u k3s -f
```

### Stuck on startup?

Check for:

* NFS mount slowness: `sudo umount -f /mnt/nasbox/etcd`
* Resource issues: `free -h` and `df -h`
* etcd errors: `journalctl -u k3s -n 100`

---

You're now running a production-ready Raspberry Pi Kubernetes control plane with secure backups, monitoring, and alerting. 🎉
