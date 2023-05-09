{{- define "keel.ingress" -}}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .app.name }}
  namespace: {{ .Release.Namespace }}
  annotations:
{{- if .app.ingress.header }}
    nginx.ingress.kubernetes.io/configuration-snippet: |
{{- range $h := .app.ingress.header }}
      more_set_headers {{ $h | quote }};
{{- end}}
{{- end }}
{{- if .app.ingress.allow }}
    nginx.ingress.kubernetes.io/whitelist-source-range: {{ join "," .app.ingress.allow | quote }}
{{- end }}
{{- if .app.ingress.deny }}
    nginx.ingress.kubernetes.io/denylist-source-range: {{ join "," .app.ingress.deny | quote }}
{{- end }}
spec:
  ingressClassName: {{ coalesce .app.ingress.name .Values.keel.ingress.name "nginx" }}
{{- if .app.ingress.secret }}
  tls:
    - hosts:
      - {{ .app.ingress.host}}
      secretName: {{ .app.ingress.secret }}
{{- end }}
  rules:
    - host: {{ .app.ingress.host}}
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            # This assumes http-svc exists and routes to healthy endpoints
            service:
              name: {{ .app.name }}
              port:
                number: {{ .app.ingress.port }}
{{- end }}
