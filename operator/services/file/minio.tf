resource "null_resource" "minio_helm_repo" {
  provisioner "local-exec" {
    command = "helm repo add ${var.file_internal.chart_base} ${var.file_internal.chart_repository} && helm repo update"
  }
}

resource "helm_release" "minio_operator" {
  depends_on = [null_resource.minio_helm_repo]

  name       = "${var.file_internal.service}-operator"
  namespace  = var.app.namespace

  chart      = var.file_internal.operator.chart
  version    = var.file_internal.operator.chart_version

  values = [
    yamlencode({
      operator = {
        containerSecurityContext = {
          runAsUser  = tonumber(local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1000) : 1000)
          runAsGroup = tonumber(local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1000) : 1000)
          fsGroup    = tonumber(local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1000) : 1000)
        }
        nodeSelector = {
          node = var.file.node
        }
        replicaCount    = var.file.operator.replicas
        securityContext = {
          runAsUser  = tonumber(local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1000) : 1000)
          runAsGroup = tonumber(local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1000) : 1000)
          fsGroup    = tonumber(local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1000) : 1000)
        }
      }
    })
  ]
}

resource "helm_release" "minio_tenant" {
  depends_on = [helm_release.minio_operator]

  name       = "${var.file_internal.service}-tenant"
  namespace  = var.app.namespace

  chart      = var.file_internal.tenant.chart
  version    = var.file_internal.tenant.chart_version

  values = [
    yamlencode({
      tenant = {
        configSecret = {
          accessKey = var.file.access_key
          secretKey = var.file.access_secret
        }
        name = "${var.file_internal.service}-tenant"
        nodeSelector = {
          node = var.file.node
        }
        pools = [{
          containerSecurityContext = {
            runAsUser  = tonumber(local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1000) : 1000)
            runAsGroup = tonumber(local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1000) : 1000)
            fsGroup    = tonumber(local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1000) : 1000)
          }
          name = "${var.file_internal.service}-tenant-pool-0"
          nodeSelector = {
            node = var.file.node
          }
          securityContext = {
            runAsUser  = tonumber(local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.UID, 1000) : 1000)
            runAsGroup = tonumber(local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1000) : 1000)
            fsGroup    = tonumber(local.is_openshift ? coalesce(data.external.get_uid_gid[0].result.GID, 1000) : 1000)
          }
          servers          = var.file.pool_servers
          size             = var.file.pool_size
          volumesPerServer = var.file.pool_server_volumes
        }]
        resources = var.file.resources
      }
    })
  ]
}