{{- define "overhang-backend-config.fullname" -}}
{{- printf "%s" .Release.Name "overhang-backend-config" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
