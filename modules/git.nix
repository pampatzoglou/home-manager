{ lib, ... }:

{
  # Git Configuration
  # Manual setup required - see DEVELOPER_IDENTITY.md for details

  home.file.".config/git/ignore".text = ''
    # --- OS-specific ---
    .DS_Store
    Thumbs.db
    ehthumbs.db
    Desktop.ini

    # --- Editor / IDE ---
    .idea/
    .vscode/
    *.swp
    *.swo
    *.bak
    *.tmp
    *.orig

    # --- Logs / temp ---
    *.log
    *.pid
    *.seed
    *.pid.lock
    *.coverage
    .pytest_cache/
    .cache/

    # --- Environment / secrets ---
    .env
    .env.*
    *.secret
    *.secrets.*
    secrets.yaml
    *.key
    *.pem
    *.crt
    *.cert
    *.p12
    *.jks
    *.pfx
    *.backup
    *.bak
    *.vault.yml
    .vault-token

    # --- Node ---
    node_modules/
    npm-debug.log*
    yarn-error.log*
    pnpm-debug.log*
    package-lock.json
    yarn.lock

    # --- Python ---
    __pycache__/
    *.pyc
    *.pyo
    *.pyd
    .venv/
    venv/
    .tox/
    .mypy_cache/
    .pytest_cache/
    .coverage*

    # --- Go ---
    bin/
    dist/
    *.test
    coverage.out

    # --- Rust ---
    target/

    # --- Java ---
    *.class
    *.jar
    *.war
    *.ear
    *.iml

    # --- Terraform ---
    .terraform/
    terraform.tfstate
    terraform.tfstate.*
    crash.log

    # --- Pulumi ---
    .pulumi/
    Pulumi.*.yaml
    Pulumi.*.json

    # --- Kubernetes / Helm ---
    charts/*/charts/
    tmp/
    *.kubeconfig
    *.kube
    kustomize.config.yaml
    .skaffold/
    *.rendered.yaml

    # --- Docker ---
    .docker/
    docker-compose.override.yml
    *-override.yml

    # --- Cloud ---
    .aws/
    .azure/
    .kube/
    .k9s/
    .terraform.d/
    .config/gcloud/
    .hcloud/
    .mc/
    .boto

    # --- Databases ---
    *.db
    *.sqlite
    *.sql
    pgdata/
    dump.rdb

    # --- Archives ---
    *.gz
    *.zip
    *.tar
    *.tgz
    *.7z
    *.img
    *.qcow2
    *.iso
    *.box

    # --- Misc ---
    .history
    .rej
  '';

  # Git configuration reminder
  home.activation.setupGitIdentity = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo ""
    echo "=== Git Configuration ==="
    echo ""
    echo "✓ Global gitignore created: ~/.config/git/ignore"
    echo ""
    echo "⚠️  Manual Git configuration required:"
    echo ""
    echo "📝 ~/.gitconfig (global identity):"
    echo "  [user]"
    echo "    name = <your-name>"
    echo "    email = <your-email@example.com>"
    echo "    signingkey = ~/.ssh/id_ed25519.pub"
    echo "  [gpg]"
    echo "    format = ssh"
    echo "  [commit]"
    echo "    gpgsign = true"
    echo "  [tag]"
    echo "    gpgsign = true"
    echo "  [core]"
    echo "    excludesFile = ~/.config/git/ignore"
    echo "    untrackedCache = true"
    echo "    sshCommand = ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes -o IdentityAgent=none"
    echo "  [init]"
    echo "    defaultBranch = main"
    echo "  [pull]"
    echo "    rebase = true"
    echo "  [fetch]"
    echo "    prune = true"
    echo "  [rerere]"
    echo "    enabled = true"
    echo "  [diff]"
    echo "    colorMoved = zebra"
    echo "  [log]"
    echo "    date = iso"
    echo "  [rebase]"
    echo "    autosquash = true"
    echo "  [push]"
    echo "    autoSetupRemote = true"
    echo "  [includeIf \"gitdir:~/Projects/work/\"]"
    echo "    path = ~/.config/git/work"
    echo ""
    echo "📝 ~/.config/git/work (work identity):"
    echo "  [user]"
    echo "    name = <work-name>"
    echo "    email = <work-email@company.com>"
    echo "    signingkey = ~/.ssh/id_ed25519_work.pub"
    echo "  [gpg]"
    echo "    format = ssh"
    echo "  [core]"
    echo "    sshCommand = ssh -i ~/.ssh/id_ed25519_work -o IdentitiesOnly=yes -o IdentityAgent=none"
    echo ""
    echo "📚 See DEVELOPER_IDENTITY.md for full configuration details"
    echo ""
  '';
}
