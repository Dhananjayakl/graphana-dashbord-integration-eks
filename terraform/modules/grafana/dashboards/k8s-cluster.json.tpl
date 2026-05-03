{
  "title": "${environment} — K8s Cluster Overview",
  "uid": "k8s-cluster-${environment}",
  "tags": ["kubernetes", "${environment}", "cluster"],
  "timezone": "browser",
  "schemaVersion": 38,
  "refresh": "30s",
  "time": { "from": "now-1h", "to": "now" },
  "templating": {
    "list": [
      {
        "name": "namespace",
        "type": "constant",
        "current": { "value": "${namespace}" },
        "hide": 0,
        "label": "Namespace"
      }
    ]
  },
  "panels": [
    {
      "id": 1,
      "title": "CPU Usage — $namespace",
      "type": "timeseries",
      "gridPos": { "x": 0, "y": 0, "w": 12, "h": 8 },
      "datasource": { "type": "prometheus", "uid": "${datasource_name}" },
      "targets": [
        {
          "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"${namespace}\", container!=\"\"}[5m])) by (pod)",
          "legendFormat": "{{pod}}",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percentunit",
          "color": { "mode": "palette-classic" }
        }
      }
    },
    {
      "id": 2,
      "title": "Memory Usage — $namespace",
      "type": "timeseries",
      "gridPos": { "x": 12, "y": 0, "w": 12, "h": 8 },
      "datasource": { "type": "prometheus", "uid": "${datasource_name}" },
      "targets": [
        {
          "expr": "sum(container_memory_working_set_bytes{namespace=\"${namespace}\", container!=\"\"}) by (pod)",
          "legendFormat": "{{pod}}",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "bytes",
          "color": { "mode": "palette-classic" }
        }
      }
    },
    {
      "id": 3,
      "title": "Pod Count — $namespace",
      "type": "stat",
      "gridPos": { "x": 0, "y": 8, "w": 4, "h": 4 },
      "datasource": { "type": "prometheus", "uid": "${datasource_name}" },
      "targets": [
        {
          "expr": "count(kube_pod_info{namespace=\"${namespace}\"})",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 8 },
              { "color": "red", "value": 15 }
            ]
          }
        }
      }
    },
    {
      "id": 4,
      "title": "Running Pods — $namespace",
      "type": "stat",
      "gridPos": { "x": 4, "y": 8, "w": 4, "h": 4 },
      "datasource": { "type": "prometheus", "uid": "${datasource_name}" },
      "targets": [
        {
          "expr": "count(kube_pod_status_phase{namespace=\"${namespace}\", phase=\"Running\"})",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "color": { "fixedColor": "green", "mode": "fixed" }
        }
      }
    },
    {
      "id": 5,
      "title": "Pending / Failed Pods — $namespace",
      "type": "stat",
      "gridPos": { "x": 8, "y": 8, "w": 4, "h": 4 },
      "datasource": { "type": "prometheus", "uid": "${datasource_name}" },
      "targets": [
        {
          "expr": "count(kube_pod_status_phase{namespace=\"${namespace}\", phase=~\"Pending|Failed\"}) or vector(0)",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "green", "value": null },
              { "color": "red", "value": 1 }
            ]
          }
        }
      }
    },
    {
      "id": 6,
      "title": "Node CPU Usage",
      "type": "gauge",
      "gridPos": { "x": 12, "y": 8, "w": 6, "h": 4 },
      "datasource": { "type": "prometheus", "uid": "${datasource_name}" },
      "targets": [
        {
          "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
          "legendFormat": "{{instance}}",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent",
          "max": 100,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 70 },
              { "color": "red", "value": 90 }
            ]
          }
        }
      }
    },
    {
      "id": 7,
      "title": "Node Memory Usage",
      "type": "gauge",
      "gridPos": { "x": 18, "y": 8, "w": 6, "h": 4 },
      "datasource": { "type": "prometheus", "uid": "${datasource_name}" },
      "targets": [
        {
          "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
          "legendFormat": "{{instance}}",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent",
          "max": 100,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 75 },
              { "color": "red", "value": 90 }
            ]
          }
        }
      }
    },
    {
      "id": 8,
      "title": "Network I/O — $namespace",
      "type": "timeseries",
      "gridPos": { "x": 0, "y": 12, "w": 24, "h": 8 },
      "datasource": { "type": "prometheus", "uid": "${datasource_name}" },
      "targets": [
        {
          "expr": "sum(rate(container_network_receive_bytes_total{namespace=\"${namespace}\"}[5m])) by (pod)",
          "legendFormat": "rx — {{pod}}",
          "refId": "A"
        },
        {
          "expr": "sum(rate(container_network_transmit_bytes_total{namespace=\"${namespace}\"}[5m])) by (pod)",
          "legendFormat": "tx — {{pod}}",
          "refId": "B"
        }
      ],
      "fieldConfig": {
        "defaults": { "unit": "bytes" }
      }
    }
  ]
}
