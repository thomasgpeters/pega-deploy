{{- define "pegaVolumeInstall" }}pega-volume-installer{{- end }}
{{- define "pegaInstallConfig" }}pega-install-config{{- end }}
{{- define "pegaUpgradeConfig" }}pega-upgrade-config{{- end }}
{{- define "pegaDBInstall" -}}pega-db-install{{- end -}}
{{- define "pegaDBInstallerContainer" -}}pega-installer{{- end -}}
{{- define "pegaDBCustomUpgrade" -}}
{{- if (contains "," .Values.upgrade.upgradeSteps) -}}
    pega-db-custom-upgrade
{{- else -}}
{{- $jobName := printf "%s-%s" "pega-db-upgrade" .Values.upgrade.upgradeSteps -}}
{{- $jobName | replace "_" "-" -}}
{{- end -}}
{{- end -}}
{{- define "pegaDBOOPRulesUpgrade" -}}pega-db-ooprules-upgrade{{- end -}}
{{- define "pegaDBOOPDataUpgrade" -}}pega-db-oopdata-upgrade{{- end -}}
{{- define "pegaDBZDTUpgrade" -}}pega-zdt-upgrade{{- end -}}
{{- define "pegaDBInPlaceUpgrade" -}}pega-in-place-upgrade{{- end -}}
{{- define "installerConfig" -}}installer-config{{- end -}}
{{- define "installerJobReaderRole" -}}jobs-reader{{- end -}}
{{- define "pegaPreDBUpgrade" -}}pega-pre-upgrade{{- end -}}
{{- define "pegaPostDBUpgrade" -}}pega-post-upgrade{{- end -}}
{{- define "pegaInstallEnvironmentConfig" -}}pega-install-environment-config{{- end -}}
{{- define "pegaUpgradeEnvironmentConfig" -}}pega-upgrade-environment-config{{- end -}}
{{- define "pegaDistributionKitVolume" -}}pega-distribution-kit-volume{{- end -}}

{{- define "installerDeploymentName" }}{{ $deploymentNamePrefix := "pega" }}{{ if (.Values.global.deployment) }}{{ if (.Values.global.deployment.name) }}{{ $deploymentNamePrefix = .Values.global.deployment.name }}{{ end }}{{ end }}{{ $deploymentNamePrefix }}{{- end }}

{{- define "performInstall" }}
  {{- if or (eq .Values.global.actions.execute "install") (eq .Values.global.actions.execute "install-deploy") -}}
    true
  {{- else -}}
    false
  {{- end -}}
{{- end }}

{{- define "performUpgrade" }}
  {{- if or (eq .Values.global.actions.execute "upgrade") (eq .Values.global.actions.execute "upgrade-deploy") -}}
    true
  {{- else -}}
    false
  {{- end -}}
{{- end }}

{{- define "performOnlyUpgrade" }}
  {{- if (eq .Values.global.actions.execute "upgrade") -}}
    true
  {{- else -}}
    false
  {{- end -}}
{{- end }}

{{- define "waitForPegaDBInstall" -}}
- name: wait-for-pegainstall
  image: dcasavant/k8s-wait-for
  args: [ 'job', '{{ template "pegaDBInstall" }}']
{{- end }}

{{- define "waitForPegaDBZDTUpgrade" -}}
- name: wait-for-pegaupgrade
  image: dcasavant/k8s-wait-for
  args: [ 'job', '{{ template "pegaDBZDTUpgrade" }}']
{{- include "initContainerEnvs" $ }}
{{- end }}

{{- define "waitForPreDBUpgrade" -}}
- name: wait-for-pre-dbupgrade
  image: dcasavant/k8s-wait-for
  args: [ 'job', '{{ template "pegaPreDBUpgrade" }}']
{{- end }}

{{- define "waitForRollingUpdates" -}}
{{- $deploymentName := printf "%s-" (include "installerDeploymentName" $) -}}
{{- $deploymentNameRegex := printf "%s- " (include "installerDeploymentName" $) -}}
{{- $rolloutCommand := "" }}
{{- $kindName := "" }}
{{- $lastIndex := sub (len .Values.global.tier) 1 }}
{{- $namespace := .Release.Namespace }}
{{- range $index, $dep := .Values.global.tier }}
{{- if ($dep.volumeClaimTemplate) }}
{{- $kindName = "statefulset" }}
{{- else -}}
{{- $kindName = "deployment" }}
{{- end }}
{{- $constructCommand := cat "kubectl rollout status" $kindName "/" $deploymentName $dep.name "--namespace" $namespace }}
{{- if ne $index $lastIndex }}
{{- $rolloutCommand = cat $rolloutCommand $constructCommand "&&" }}
{{- else }}
{{- $rolloutCommand = cat $rolloutCommand $constructCommand }}
{{- end }}
{{- $rolloutCommand = regexReplaceAllLiteral " / " $rolloutCommand "/" }}
{{- $rolloutCommand = regexReplaceAllLiteral $deploymentNameRegex $rolloutCommand $deploymentName }}
{{- end -}}
- name: wait-for-rolling-updates
  image: dcasavant/k8s-wait-for
  command: ['sh', '-c',  '{{ $rolloutCommand }}' ]
{{- include "initContainerEnvs" $ }}
{{- end }}

{{- define "initContainerEnvs" -}}
{{- if or (eq .Values.global.provider "aks") (eq .Values.global.provider "pks") -}}
{{ $apiserver := index .Values.global.upgrade "kube-apiserver" }}
  env:
  - name: KUBERNETES_SERVICE_HOST
    value: {{ $apiserver.serviceHost | quote }}
  - name: KUBERNETES_SERVICE_PORT_HTTPS
    value: {{ $apiserver.httpsServicePort | quote }}
  - name: KUBERNETES_SERVICE_PORT
    value: {{ $apiserver.httpsServicePort | quote }}
{{- end }}
{{- end }}
