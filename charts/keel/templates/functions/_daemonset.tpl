{{- define "keel.daemonset" -}}
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: {{ .app.name }}-crontab
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    matchLabels:
      app: {{ .app.name }}-crontab
  template:
    metadata:
      labels:
        app: {{ .app.name }}-crontab
    spec:
{{- if .app.nodeAffinity }}
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: {{ .app.nodeAffinity.key }}
                    operator: In
                    values:
                      - {{ .app.nodeAffinity.value }}
{{- end }}
{{- if .Values.keel.image.pullSecrets }}
      imagePullSecrets:
{{ toYaml .Values.keel.image.pullSecrets | indent 8 }}
{{- end }}
      containers:
        - name: crontab
          image: {{ .Values.keel.image.repository }}/crontab:latest
          imagePullPolicy: {{ default "Always" .Values.keel.image.pullPolicy }}
          env:
            - name: CRONTAB_PATH
              value: {{ .app.crontabPath }}
            - name: REVISION
              value: {{ quote .Release.Revision }}
          volumeMounts:
            - name: localtime
              mountPath: /etc/localtime
            - name: logs
              mountPath: {{ .app.log.path }}
            - name: crontab-conf
              mountPath: /etc/crontab
              subPath: crontab
            - name: crontab-scripts
              mountPath: {{ .app.crontabPath }}
      volumes:
        - name: localtime
          hostPath:
            path: /etc/localtime
        - name: logs
          hostPath:
            path: {{ .app.log.hostPath }}
        - name: crontab-conf
          configMap:
            name: {{ .app.name }}-crontab-conf
        - name: crontab-scripts
          configMap:
            name: {{ .app.name }}-crontab-scripts
{{- end }}
