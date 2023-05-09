{{- define "keel.virtualserver" -}}
---
apiVersion: k8s.nginx.org/v1
kind: VirtualServer
metadata:
  name: {{ .app.name }}
  namespace: {{ .Release.Namespace }}
spec:
  host: {{ .app.ingress.host}}
{{- if .app.ingress.secret }}
  tls:
    secret: {{ .app.ingress.secret }}
{{- end }}
  upstreams:
    - name: {{ .app.name }}
      service: {{ .app.name }}
      port: {{ .app.ingress.port }}
  routes:
    - path: /
      action:
        pass: {{ .app.name }}
{{- end }}