{{- define "keel.service" -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .app.name }}
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    app: {{ .app.name }}
  type: {{ default "ClusterIP" .app.service.type }}
  ports:
{{- $service := .app.service }}
{{- range .app.service.ports }}
  - port: {{ .port }}
    targetPort: {{ .port }}
    name: {{ include "keel.port_name" . }}
    protocol: TCP
{{- if (and (eq $service.type "NodePort") (not (empty .nodePort))) }}
    nodePort: {{ .nodePort }}
{{- end }}
{{- end }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ printf "%s-headless" .app.name }}
  namespace: {{ .Release.Namespace }}
spec:
  clusterIP: None
  selector:
    app: {{ .app.name }}
  ports:
{{- range .app.service.ports }}
  - port: {{ .port }}
    name: {{ include "keel.port_name" . }}
{{- end }}
{{- end }}
