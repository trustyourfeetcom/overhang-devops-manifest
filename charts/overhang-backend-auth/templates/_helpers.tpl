{{- define "overhang-backend-auth.fullname" -}}
{{- printf "%s" .Release.Name "overhang-backend-auth" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
