
# <img src="https://trino.io/assets/trino.png" width="10%"> | Trino

Fast distributed SQL query engine for big data analytics that helps you explore your data universe

## Trino-Ranger-Plugin

<b>Trino-ranger-plugin</b> communicates with <b>Ranger Admin</b> to check and download the access policies which will be then synced with Trino Server. The downloaded policies are stored as json files on the Trino server under the <b>/etc/ranger/trino/policycache</b> folder.

It was not possible to integrate the <b>ranger</b> plug-in using the official Trino container image due to security restrictions.

We used Kubernetes' init-container feature to overcome this hurdle and install the <b>ranger</b>plug-in.

You can find the work on [this](https://github.com/SwanseaUniversityMedical/SeRP-Trino/tree/main/ranger/trino-init) repo.

### Note
_This plug-in and <b>ranger-admin</b> builds are community edition since the official version has not been released yet._

For implementing <b>ranger</b> plug-in into <b>Trino</b> we modified official <b>Trino</b> Helm chart version <b>0.7.0</b> and it can be find [here](https://github.com/SwanseaUniversityMedical/SeRP-Trino/tree/main/charts/trino).

On the [deployment-coordinator.yaml](https://github.com/SwanseaUniversityMedical/SeRP-Trino/blob/main/charts/trino/templates/deployment-coordinator.yaml) file, we added the following configuration to <b>initContainer</b> section.

```
      initContainers:
        - name: init-coordinator
          image: "{{ .Values.initImage.repository }}:{{ .Values.initImage.tag }}"
          imagePullPolicy: {{ .Values.initImage.pullPolicy }}
          volumeMounts:
            - mountPath: /etc/trino
              name: trino-storage
            - mountPath: /usr/lib/trino/plugin/ranger
              name: ranger-storage
            - mountPath: /etc/ranger-2.1.0-trino-plugin
              name: ranger-plugin
            - mountPath: {{ .Values.server.config.path }}/catalog
              name: catalog-volume
            {{- range .Values.secretMounts }}
            - name: {{ .name }}
              mountPath: {{ .path }}
            {{- end }}
            {{- if eq .Values.server.config.authenticationType "PASSWORD" }}
            - mountPath: {{ .Values.server.config.path }}/auth
              name: password-volume
            {{- end }}
```
Kubernetes volumes help us to mount files and folders without permission issue. And we are moving these files and folders to <b>trino-coordinator</b> container on the following configuration.

```
      containers:
        - name: {{ .Chart.Name }}-coordinator
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          securityContext:
            runAsUser: {{ .runAsUser }}
            runAsGroup: {{ .runAsGroup }}
          env:
            {{- toYaml .Values.env | nindent 12 }}
          volumeMounts:
            - mountPath: /etc/trino
              name: trino-storage
            - mountPath: /etc/trino/catalog
              name: catalog-volume
            - mountPath: /etc/trino/config.properties
              name: config-volume
              subPath: config.properties
            - mountPath: /etc/trino/jvm.config
              name: config-volume
              subPath: jvm.config
            - mountPath: /etc/trino/log.properties
              name: config-volume
              subPath: log.properties
            - mountPath: /etc/trino/node.properties
              name: config-volume
              subPath: node.properties
            - mountPath: /usr/lib/trino/plugin/ranger
              name: ranger-storage
            - mountPath: /etc/ranger-2.1.0-trino-plugin
              name: ranger-plugin
```
<br>

## Adding MinIO catalog to Trino

In the <b>Trino</b> helm chart [values.yaml](https://github.com/SwanseaUniversityMedical/SeRP-Trino/blob/main/charts/trino/values.yaml) file, we configured <b>MinIO</b> catalog under the <b>additionalCatalogs</b> section. In this section, we musn't forget, <b>S3</b> configuration must same with <b>Hive-metastore's S3</b> configuration.

```
additionalCatalogs:
    minio: |
      connector.name = hive-hadoop2
      hive.metastore.uri = thrift://hive-metastore:9083
      hive.s3.path-style-access=true
      hive.s3.endpoint=http://minio:9000
      hive.s3.aws-access-key=console
      hive.s3.aws-secret-key=console123
      hive.non-managed-table-writes-enabled=true
      hive.s3select-pushdown.enabled=true
      hive.storage-format=ORC
      hive.allow-drop-table=true
```
<br>

## Helm Chart Deployment

All we need to do, run the helm install command and install <b>Trino</b> deployment to target namespace.
```
helm install trino ./trino -n <namespace>
```
If we have custom configured values.yaml file, we can pass with <b>-f</b> option.

<br>

## Configuration

The following table lists the configurable parameters of the Trino chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `image.repository` |  | `"trinodb/trino"` |
| `image.pullPolicy` |  | `"IfNotPresent"` |
| `image.tag` |  | `"latest"` |
| `imagePullSecrets` |  | `[{"name": "registry-credentials"}]` |
| `server.workers` |  | `2` |
| `server.node.environment` |  | `"production"` |
| `server.node.dataDir` |  | `"/data/trino"` |
| `server.node.pluginDir` |  | `"/usr/lib/trino/plugin"` |
| `server.log.trino.level` |  | `"INFO"` |
| `server.config.path` |  | `"/etc/trino"` |
| `server.config.http.port` |  | `8080` |
| `server.config.https.enabled` |  | `false` |
| `server.config.https.port` |  | `8443` |
| `server.config.https.keystore.path` |  | `""` |
| `server.config.authenticationType` |  | `""` |
| `server.config.query.maxMemory` |  | `"4GB"` |
| `server.config.query.maxMemoryPerNode` |  | `"1GB"` |
| `server.config.memory.heapHeadroomPerNode` |  | `"1GB"` |
| `server.exchangeManager.name` |  | `"filesystem"` |
| `server.exchangeManager.baseDir` |  | `"/tmp/trino-local-file-system-exchange-manager"` |
| `server.workerExtraConfig` |  | `""` |
| `server.coordinatorExtraConfig` |  | `""` |
| `server.autoscaling.enabled` |  | `false` |
| `server.autoscaling.maxReplicas` |  | `5` |
| `server.autoscaling.targetCPUUtilizationPercentage` |  | `50` |
| `additionalNodeProperties` |  | `{}` |
| `additionalConfigProperties` |  | `{}` |
| `additionalLogProperties` |  | `{}` |
| `additionalExchangeManagerProperties` |  | `{}` |
| `eventListenerProperties` |  | `{}` |
| `additionalCatalogs` |  | `{}` |
| `env` |  | `[]` |
| `initContainers` |  | `{}` |
| `securityContext.runAsUser` |  | `1000` |
| `securityContext.runAsGroup` |  | `1000` |
| `service.type` |  | `"ClusterIP"` |
| `service.port` |  | `8080` |
| `nodeSelector` |  | `{}` |
| `tolerations` |  | `[]` |
| `affinity` |  | `{}` |
| `auth` |  | `{}` |
| `serviceAccount.create` |  | `false` |
| `serviceAccount.name` |  | `""` |
| `serviceAccount.annotations` |  | `{}` |
| `secretMounts` |  | `[]` |
| `coordinator.jvm.maxHeapSize` |  | `"8G"` |
| `coordinator.jvm.gcMethod.type` |  | `"UseG1GC"` |
| `coordinator.jvm.gcMethod.g1.heapRegionSize` |  | `"32M"` |
| `coordinator.additionalJVMConfig` |  | `{}` |
| `coordinator.resources` |  | `{}` |
| `worker.jvm.maxHeapSize` |  | `"8G"` |
| `worker.jvm.gcMethod.type` |  | `"UseG1GC"` |
| `worker.jvm.gcMethod.g1.heapRegionSize` |  | `"32M"` |
| `worker.additionalJVMConfig` |  | `{}` |
| `worker.resources` |  | `{}` |



---
_Configuration section generated by [Frigate](https://frigate.readthedocs.io)._

