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

# Keep only 7 most recent
ls -1t "$BACKUP_DIR"/etcd-snapshot-*.db | tail -n +8 | xargs rm -f