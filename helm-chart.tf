/* data "terraform_remote_state" "aks" {
  backend = "local"

  config = {
    path = "../learn-terraform-provision-aks-cluster/terraform.tfstate"
  }
} */

data "azurerm_kubernetes_cluster" "cluster" {
  name                = "${var.clustername}-aks" #data.terraform_remote_state.aks.outputs.kubernetes_cluster_name
  resource_group_name = "${var.clustername}-k8s" #data.terraform_remote_state.aks.outputs.resource_group_name
  depends_on = [
    azurerm_kubernetes_cluster.default

  ]
}

provider "helm" {
  debug = true
  kubernetes {
    host = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host

    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
  }
}

/* provider "kubernetes" {
  host = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host

  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
} */

resource "helm_release" "nginx_ingress_controller" {
  name             = "nginx-ingress-controller"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.2.5"
  namespace        = "ingress"
  create_namespace = "true"
  verify           = false
  force_update     = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "controller.autoscaling.enabled"
    value = "true"
  }
  set {
    name  = "controller.autoscaling.minReplicas"
    value = "2"
  }
  set {
    name  = "controller.autoscaling.maxReplicas"
    value = "10"
  }
}


#Deploying ArgoCD on AKS cluster using terraform
resource "helm_release" "argo_cd" {
  name             = "argo"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "4.8.2"
  namespace        = "gitops"
  create_namespace = true
  verify           = false

  # annotations:
  #   nginx.ingress.kubernetes.io/ssl-redirect: "false"
  #   nginx.ingress.kubernetes.io/use-regex: "true"
  #   nginx.ingress.kubernetes.io/rewrite-target: /$1
  set {
    name  = "server.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/ssl-redirect"
    value = "false"
    type  = "string"
  }
  set {
    name  = "server.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/use-regex"
    value = "true"
    type  = "string"
  }
  set {
    name  = "server.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/rewrite-target"
    value = "/$1"
  }
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }
  set {
    name  = "server.ingress.https"
    value = "true"
  }
  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
  }
  set {
    name  = "server.ingress.pathType"
    value = "Prefix"
  }
  set {
    name  = "server.ingress.paths"
    value = "{/argocd(.*)}" # "[\"/argocd\"]"
  }
}


/* module "nginx-controller" {
  source  = "terraform-iaac/nginx-controller/helm"
  version = "2.0.4"
  # insert the 1 required variable here
}
 */
