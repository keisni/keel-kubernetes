{{- define "keel.ingress" -}}
{{- $dot := . }}
{{- range $idx, $rule := .app.ingress.rules }}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ printf "%s-%d" $dot.app.name (int $idx) }}
  namespace: {{ $dot.Release.Namespace }}
  annotations:
{{- if $rule.disableAccessLog }}
    nginx.ingress.kubernetes.io/enable-access-log: "false"
{{- end }}
{{- if $rule.snippet }}
    nginx.ingress.kubernetes.io/configuration-snippet: {{ $rule.snippet | quote }}
{{- end }}
{{- if $rule.allow }}
    nginx.ingress.kubernetes.io/whitelist-source-range: {{ join "," $rule.allow | quote }}
{{- end }}
{{- if $rule.deny }}
    nginx.ingress.kubernetes.io/denylist-source-range: {{ join "," $rule.deny | quote }}
{{- end }}
spec:
  ingressClassName: {{ coalesce $dot.app.ingress.name $dot.Values.keel.ingress.name "nginx" }}
{{- if $dot.app.ingress.secret }}
  tls:
    - hosts:
      - {{ $dot.app.ingress.host}}
      secretName: {{ $dot.app.ingress.secret }}
{{- end }}
  rules:
    - host: {{ $dot.app.ingress.host}}
      http:
        paths:
{{- $exact := $rule.exactMatch }}
{{- range $rule.path }}
        - path: {{ . }}
          pathType: {{ if $exact }}Exact{{ else }}Prefix{{ end }}
          backend:
            service:
              name: {{ $dot.app.name }}
              port:
                number: {{ $dot.app.ingress.port }}
{{- end}}
{{- end}}
{{- end }}
