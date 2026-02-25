{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Kubernetes ecosystem tools
    kubectl
    kubelogin-oidc
    kubernetes-helm
    kubernetes-helmPlugins.helm-unittest
    kubectl-cnpg
    kubectl-linstor
    argocd
    skaffold
    istioctl
    cmctl
    velero
    kind
    krew
    k9s
    kubeshark
    tilt
    lens
    kubent
    kubesec
    testkube
    kuttl
    kyverno-chainsaw
  ];
}
