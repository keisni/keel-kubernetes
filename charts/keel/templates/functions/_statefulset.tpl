{{- define "keel.statefulset" -}}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
 name: {{ .app.name }}
 namespace: {{ .Release.Namespace }}
 labels:
   app: {{ .app.name }}
spec:
  serviceName: {{ printf "%s-headless" .app.name }}
  replicas: {{ .app.replicas }}
  selector:
    matchLabels:
      app: {{ .app.name }}
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: {{ .app.name }}
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - {{ .app.name }}
            topologyKey: kubernetes.io/hostName
{{- if .app.nodeAffinity }}
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
        - name: {{ .app.name }}
          image: "{{ .Values.keel.image.repository }}/{{ .app.name }}:{{ default "latest" .app.tag }}"
          imagePullPolicy: {{ default "Always" .Values.keel.image.pullPolicy }}
          lifecycle:
            preStop:
              exec:
                command: ["/usr/local/tomcat/bin/catalina.sh stop 20"]
          env:
          - name: KEEL_VERSION
            value: {{ include "keel.version" . | quote }}
          - name: POD_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
          - name: HOST_IP
            valueFrom:
              fieldRef:
                fieldPath: status.hostIP
          - name: CONFIG_PATH
            value: {{ .app.configPath | quote }}
{{- if .app.javaOpts}}
          - name: JAVA_OPTS
            value: {{ .app.javaOpts }}
{{- end }}
{{- if .app.resources }}
          resources:
            limits:
{{ toYaml .app.resources | indent 14 }}
{{- end }}
{{- if .app.service }}
          ports:
{{- range .app.service.ports }}
          - containerPort: {{ .port }}
            name: {{ include "keel.port_name" . }}
{{- end }}
{{- end }}
          volumeMounts:
            - name: localtime
              mountPath: /etc/localtime
            - name: logs
              mountPath: {{ .app.log.path }}
            - name: keel-shared
              mountPath: /keel/shared
            - name: update-wait
              mountPath: /keel/update
{{- $processedMount := dict -}}
{{- $mountPath := .app.configPath }}
{{- range $path, $bytes := .Files.Glob (printf "resources/%s/config/**" .app.name ) }}
{{- $sub := base (dir $path) }}
{{- if not (hasKey $processedMount $sub) -}}
{{ $_ := set $processedMount $sub "true" }}
            - name: config-{{ $sub }}
              mountPath: {{ printf "%s/%s" $mountPath $sub}}
{{- end }}
{{- end }}
{{- if .app.update }}
{{- if .app.update.script }}
            - name: app-test
              mountPath: "/app/test"
{{- end }}
{{- if or .app.update.script (and .app.update.http .app.update.http.path ) }}
          startupProbe:
{{- if .app.update.script }}
            exec:
              command:
              - /bin/bash
              - /app/test/{{ .app.update.script }}
{{- else }}
            httpGet:
              path: {{ .app.update.http.path }}
              port: {{ default 8080 .app.update.http.port }}
{{- end }}
            initialDelaySeconds: 5
            timeoutSeconds: 5
            periodSeconds: 5
            failureThreshold: 30
{{- end }}
{{- if .app.update.wait }}
          readinessProbe:
            exec:
              command:
              - /bin/bash
              - /keel/shared/wait.sh
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 0
{{- end }}
{{- end }}
      volumes:
        - name: localtime
          hostPath:
            path: /etc/localtime
        - name: logs
          hostPath:
            path: /data/{{ .Release.Namespace }}/{{ .app.name }}
        - name: keel-shared
          configMap:
            name: keel-shared
        - name: update-wait
          configMap:
            name: {{ .app.name }}-update-wait
{{- $processedDict := dict -}}
{{- $dot := . }}
{{- $appName := .app.name }}
{{- $configDir := coalesce .app.configFrom .app.name }}
{{- range $path, $bytes := .Files.Glob (printf "resources/%s/config/**" $configDir ) }}
{{- $sub := base (dir $path) }}
{{- if not (hasKey $processedDict $sub) -}}
{{ $_ := set $processedDict $sub "true" }}
        - name: config-{{ $sub }}
          configMap:
            name: {{ printf "%s-config-%s-%s" $appName $sub (include "keel.version" $dot) }}
{{- end }}
{{- end }}
{{- if and .app.update .app.update.script }}
        - name: app-test
          configMap:
            name: {{ printf "%s-config-test" $appName }}
{{- end }}
{{- end -}}
