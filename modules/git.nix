{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      # User configuration should be set manually via:
      # git config --global user.name "Your Name"
      # git config --global user.email "your.email@example.com"
      # git config --global user.signingKeyPath "~/.ssh/id_ed25519"
      
      commit.gpgsign = true;
      gpg.format = "ssh";

      # Signature verification
      log.showSignature = true;
      merge.verifySignatures = false;

      # Better diff and merge tools
      diff.algorithm = "patience";
      merge.conflictStyle = "diff3";

      # Security
      transfer.fsckObjects = true;
      fetch.fsckObjects = true;
      receive.fsckObjects = true;

      # Performance
      core.preloadindex = true;
      core.fscache = true;
      gc.auto = 256;

      # Branch cleanup
      fetch.prune = true;
      fetch.prunetags = true;
    };

    ignores = [
      # --- OS-specific ---
      ".DS_Store" "Thumbs.db" "ehthumbs.db" "Desktop.ini"

      # --- Editor / IDE ---
      ".idea/" ".vscode/" "*.swp" "*.swo" "*.bak" "*.tmp" "*.orig"

      # --- Logs / temp ---
      "*.log" "*.pid" "*.seed" "*.pid.lock" "*.coverage"
      ".pytest_cache/" ".cache/"

      # --- Environment / secrets ---
      ".env" ".env.*" "*.secret" "*.secrets.*" "secrets.yaml"
      "*.key" "*.pem" "*.crt" "*.cert" "*.p12" "*.jks" "*.pfx"
      "*.backup" "*.bak" "*.vault.yml" ".vault-token"

      # --- Node ---
      "node_modules/" "npm-debug.log*" "yarn-error.log*" "pnpm-debug.log*"
      "package-lock.json" "yarn.lock"

      # --- Python ---
      "__pycache__/" "*.pyc" "*.pyo" "*.pyd" ".venv/" "venv/" ".tox/"
      ".mypy_cache/" ".pytest_cache/" ".coverage*"

      # --- Go ---
      "bin/" "dist/" "*.test" "coverage.out"

      # --- Rust ---
      "target/"

      # --- Java ---
      "*.class" "*.jar" "*.war" "*.ear" "*.iml"

      # --- Terraform ---
      ".terraform/" "terraform.tfstate"
      "terraform.tfstate.*" "crash.log"

      # --- Pulumi ---
      ".pulumi/" "Pulumi.*.yaml" "Pulumi.*.json"

      # --- Kubernetes / Helm ---
      "charts/*/charts/" "tmp/" "*.kubeconfig" "*.kube"
      "kustomize.config.yaml" ".skaffold/" "*.rendered.yaml"

      # --- Docker ---
      ".docker/" "docker-compose.override.yml" "*-override.yml"

      # --- Cloud ---
      ".aws/" ".azure/" ".kube/" ".k9s/" ".terraform.d/"
      ".config/gcloud/" ".hcloud/" ".mc/" ".boto"

      # --- Databases ---
      "*.db" "*.sqlite" "*.sql" "pgdata/" "dump.rdb"

      # --- Archives ---
      "*.gz" "*.zip" "*.tar" "*.tgz" "*.7z" "*.img"
      "*.qcow2" "*.iso" "*.box"

      # --- Misc ---
      ".history" ".rej"
    ];

    settings.alias = {
      st = "status -sb";
      co = "checkout";
      br = "branch";
      ci = "commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";

      cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d";
      recent = "branch --sort=-committerdate";

      lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
      lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
    };
  };
}
