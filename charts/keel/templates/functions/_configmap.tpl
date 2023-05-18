{{- define "keel.configmap" -}}
---
{{- $dot := . }}
{{- $appName := .app.name }}
{{- $Release := .Release }}
{{- $Files:= .Files }}
{{- $processedDict := dict -}}
{{- $configDir := coalesce .app.configFrom .app.name }}
{{- range $path, $bytes := .Files.Glob (printf "resources/%s/config/**" $configDir) }}
{{- $sub := base (dir $path) }}
{{- if not (hasKey $processedDict $sub) -}}
{{ $_ := set $processedDict $sub "true" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $appName }}-config-{{ $sub }}-{{ include "keel.version" $dot }}
  namespace: {{ $.Release.Namespace }}
binaryData:
{{ range $subpath, $_ :=  $Files.Glob (printf "resources/%s/config/%s/*" $configDir $sub) }}
{{- $subname := base $subpath }}
{{- $subname | indent 2 }}: |
{{ $Files.Get $subpath | b64enc | indent 4}}
{{ end }}
---
{{- end }}
{{- end }}
{{- if .app.crontabPath }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .app.name }}-crontab-conf
  namespace: {{ .Release.Namespace }}
data:
  crontab: |
{{ .Files.Get (printf "resources/%s/crontab/crontab" .app.name) | indent 4}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .app.name }}-crontab-scripts
  namespace: {{ .Release.Namespace }}
data:
{{ (.Files.Glob (printf "resources/%s/crontab/scripts/*" .app.name)).AsConfig | nindent 2 }}
---
{{- end }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .app.name }}-update-wait
  namespace: {{ .Release.Namespace }}
data:
  wait: |
{{- if and .app.update .app.update.wait}}
{{ .app.update.wait | indent 4}}
{{- end }}
---
{{- if and .app.update .app.update.script }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .app.name }}-config-test
  namespace: {{ .Release.Namespace }}
data:
{{ .app.test.script | indent 2 }}: |
{{ .Files.Get (printf "resources/%s/%s" .app.name .app.test.script) | indent 4}}
---
{{- end }}
{{- end }}
