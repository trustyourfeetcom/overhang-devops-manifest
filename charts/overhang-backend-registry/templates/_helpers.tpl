{{- define "overhang-backend-registry.fullname" -}}
{{- printf "%s-%s" .Release.Name "overhang-backend-registry" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
