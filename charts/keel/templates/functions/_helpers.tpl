{{- define "keel.version" -}}
{{- coalesce .app.version .app.tag}}
{{- end }}

{{- define "keel.port_name" -}}
{{- coalesce .name (int .port | printf "port-%d" ) }}
{{- end }}
