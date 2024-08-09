{{- define "overhang-backend-gateway.fullname" -}}
{{- printf "%s" "overhang-backend-gateway" -}}
{{- end -}}

{{- define "overhang-backend-gateway.labels" -}}
app.kubernetes.io/name: {{ include "overhang-backend-gateway.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
