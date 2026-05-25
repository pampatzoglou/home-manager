{ ... }:

{
  # Git global ignore — XDG default location, git picks this up without any extra config
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
    *.key
    *.pem
    *.crt
    *.cert
    *.p12
    *.jks
    *.pfx
    *.backup
    *.bak
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

    # --- Agentic / AI ---
    **/.claude/settings.local.*
    **/.codex/
    **/.aider*
    **/.continue/
    **/.cursor/
    **/.warp/

    # --- Misc ---
    .history
    .rej
  '';
}
