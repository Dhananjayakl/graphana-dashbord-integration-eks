{
  "title": "${environment} — Namespace Detail",
  "uid": "k8s-namespace-${environment}",
  "tags": ["kubernetes", "${environment}", "namespace"],
  "timezone": "browser",
  "schemaVersion": 38,
  "refresh": "30s",
  "time": { "from": "now-3h", "to": "now" },
  "panels": [
    {
      "id": 1,
      "title": "Deployment Replicas Available vs Desired",
      "type": "timeseries",
      "gridPos": { "x": 0, "y": 0, "w": 24, "h": 8 },
      "datasource": { "type": "prometheus", "uid": "${datasource_name}" },
      "targets": [
        {
          "expr": "kube_deployment_status_replicas_available{namespace=\"${namespace}\"}",
          "legendFormat": "available — {{deployment}}",
          "refId": "A"
        },
        {
          "expr": "kube_deployment_spec_replicas{namespace=\"${namespace}\"}",
          "legendFormat": "desired — {{deployment}}",
          "refId": "B"
        }
      ]
    },
    {
      "id": 2,
      "title": "Container Restarts — $namespace",
      "type": "timeseries",
      "gridPos": { "x": 0, "y": 8, "w": 12, "h": 8 },
      "datasource": { "type": "prometheus", "uid": "${datasource_name}" },
      "targets": [
        {
          "expr": "increase(kube_pod_container_status_restarts_total{namespace=\"${namespace}\"}[1h])",
          "legendFormat": "{{pod}} / {{container}}",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 3 },
              { "color": "red", "value": 10 }
            ]
          }
        }
      }
    },
    {
      "id": 3,
      "title": "HPA — Current vs Min vs Max Replicas",
      "type": "timeseries",
      "gridPos": { "x": 12, "y": 8, "w": 12, "h": 8 },
      "datasource": { "type": "prometheus", "uid": "${datasource_name}" },
      "targets": [
        {
          "expr": "kube_horizontalpodautoscaler_status_current_replicas{namespace=\"${namespace}\"}",
          "legendFormat": "current",
          "refId": "A"
        },
        {
          "expr": "kube_horizontalpodautoscaler_spec_min_replicas{namespace=\"${namespace}\"}",
          "legendFormat": "min",
          "refId": "B"
        },
        {
          "expr": "kube_horizontalpodautoscaler_spec_max_replicas{namespace=\"${namespace}\"}",
          "legendFormat": "max",
          "refId": "C"
        }
      ]
    }
  ]
}
