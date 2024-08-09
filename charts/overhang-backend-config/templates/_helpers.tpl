{{- define "overhang-backend-config.fullname" -}}
{{- printf "%s-%s" .Release.Name "overhang-backend-config" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
