{{- define "overhang-backend-auth.fullname" -}}
{{- printf "%s-%s" .Release.Name "overhang-backend-auth" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
