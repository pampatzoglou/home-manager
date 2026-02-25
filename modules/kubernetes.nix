{ config, pkgs, lib, ... }:

{
  # Kubectl and Kubernetes ecosystem configuration

  # Install krew plugins automatically via activation scripts
  home.activation.installKrewPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.krew}/bin:$PATH"

    # Initialize krew if not already done
    if [ ! -d "${config.home.homeDirectory}/.krew" ]; then
      echo "Initializing krew..."
      ${pkgs.krew}/bin/kubectl-krew install krew || echo "Krew already initialized or install failed"
    fi

    # Install useful kubectl plugins via krew
    echo "Installing kubectl plugins via krew..."

    # kubevpn - Kubernetes VPN connectivity
    ${pkgs.krew}/bin/kubectl-krew install vn 2>/dev/null || echo "vn plugin already installed or unavailable"

    # kubectl-tree - Show resource ownership tree
    ${pkgs.krew}/bin/kubectl-krew install tree 2>/dev/null || echo "tree plugin already installed or unavailable"

    # kubectl-who-can - RBAC explorer
    ${pkgs.krew}/bin/kubectl-krew install who-can 2>/dev/null || echo "who-can plugin already installed or unavailable"

    # kubectl-neat - Clean up kubectl output
    ${pkgs.krew}/bin/kubectl-krew install neat 2>/dev/null || echo "neat plugin already installed or unavailable"

    # kubectl-ctx - Context switching
    ${pkgs.krew}/bin/kubectl-krew install ctx 2>/dev/null || echo "ctx plugin already installed or unavailable"

    # kubectl-ns - Namespace switching
    ${pkgs.krew}/bin/kubectl-krew install ns 2>/dev/null || echo "ns plugin already installed or unavailable"

    # kubectl-outdated - Find outdated images
    ${pkgs.krew}/bin/kubectl-krew install outdated 2>/dev/null || echo "outdated plugin already installed or unavailable"

    # kubectl-resource-capacity - Resource usage overview
    ${pkgs.krew}/bin/kubectl-krew install resource-capacity 2>/dev/null || echo "resource-capacity plugin already installed or unavailable"

    # kubectl-cost - Cost analysis
    ${pkgs.krew}/bin/kubectl-krew install cost 2>/dev/null || echo "cost plugin already installed or unavailable"

    echo "Krew plugins installation complete"
  '';

  # Kubectl configuration and aliases (via shell)
  home.file.".kube/.gitignore".text = ''
    # Ignore sensitive kubeconfig files in git
    config
    *.kubeconfig
    *.yaml
    *.yml

    # Keep cache and other files
    cache/
    http-cache/
  '';

  # Create a kubectl completion and helper script
  home.file.".local/bin/k8s-helper".text = ''
    #!/bin/bash

    # Kubernetes helper functions

    # Quick pod logs
    klogs() {
      if [ $# -eq 0 ]; then
        echo "Usage: klogs <pod-name> [container-name]"
        return 1
      fi

      if [ $# -eq 1 ]; then
        kubectl logs -f "$1"
      else
        kubectl logs -f "$1" -c "$2"
      fi
    }

    # Quick exec into pod
    kexec() {
      if [ $# -eq 0 ]; then
        echo "Usage: kexec <pod-name> [command]"
        return 1
      fi

      local cmd=''${2:-/bin/bash}
      kubectl exec -it "$1" -- $cmd
    }

    # Get pod by app label
    kgetapp() {
      if [ $# -eq 0 ]; then
        echo "Usage: kgetapp <app-name>"
        return 1
      fi

      kubectl get pods -l app="$1"
    }

    # Quick describe
    kdesc() {
      if [ $# -eq 0 ]; then
        echo "Usage: kdesc <resource> [name]"
        return 1
      fi

      if [ $# -eq 1 ]; then
        kubectl describe "$1"
      else
        kubectl describe "$1" "$2"
      fi
    }

    # Quick port forwarding
    kport() {
      if [ $# -lt 2 ]; then
        echo "Usage: kport <local-port> <pod-name> [pod-port]"
        return 1
      fi

      local pod_port=''${3:-$1}
      kubectl port-forward "$2" "$1:$pod_port"
    }

    # Show resource usage
    ktop() {
      kubectl top nodes
      echo ""
      kubectl top pods --all-namespaces
    }

    # Quick context and namespace info
    kinfo() {
      echo "Current Context: $(kubectl config current-context)"
      echo "Current Namespace: $(kubectl config view --minify --output 'jsonpath={..namespace}')"
      echo ""
      echo "Available Contexts:"
      kubectl config get-contexts
    }

    # Function dispatcher
    case "$1" in
      logs) shift; klogs "$@" ;;
      exec) shift; kexec "$@" ;;
      app) shift; kgetapp "$@" ;;
      desc) shift; kdesc "$@" ;;
      port) shift; kport "$@" ;;
      top) ktop ;;
      info) kinfo ;;
      *)
        echo "Available k8s-helper commands:"
        echo "  logs <pod> [container]  - Follow pod logs"
        echo "  exec <pod> [command]    - Execute into pod"
        echo "  app <app-name>          - Get pods by app label"
        echo "  desc <resource> [name]  - Describe resource"
        echo "  port <local> <pod> [pod-port] - Port forward"
        echo "  top                     - Resource usage"
        echo "  info                    - Context and namespace info"
        ;;
    esac
  '';

  home.file.".local/bin/k8s-helper".executable = true;
}
