{ ... }:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    envExtra = ''
      # Source nix-daemon to set up PATH for nix-profile and nix default bins
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
    '';
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    history = {
      size = 50000;
      save = 50000;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      # General
      k = "kubectl";
      tf = "terraform";
      ll = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
      cc = "noglob _cc";

      # Git
      gc = "git commit -m";
      gca = "git commit -a -m";
      gp = "git push origin HEAD";
      gpu = "git pull origin";
      gst = "git status";
      gs = "git status";
      glog =
        "git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit";
      gdiff = "git diff";
      gco = "git checkout";
      gb = "git branch";
      gba = "git branch -a";
      gadd = "git add";
      ga = "git add -p";
      gcoall = "git checkout -- .";
      gr = "git remote";
      gre = "git reset";

      # Kubernetes shortcuts
      kgp = "kubectl get pods";
      kgs = "kubectl get services";
      kgd = "kubectl get deployments";
      kdp = "kubectl describe pod";
      kds = "kubectl describe service";
      kdd = "kubectl describe deployment";

      # Terraform shortcuts
      tfi = "terraform init";
      tfp = "terraform plan";
      tfa = "terraform apply";
      tfd = "terraform destroy";
      tfv = "terraform validate";
      tff = "terraform fmt";

      # Docker shortcuts (modern docker compose v2 syntax)
      d = "docker";
      dc = "docker compose"; # Modern v2 syntax
      dcu = "docker compose up -d";
      dcd = "docker compose down";
      dcl = "docker compose logs -f";
      dcr = "docker compose restart";
      dps = "docker ps";
      dpsa = "docker ps -a";
      di = "docker images";
      drm = "docker rm";
      drmi = "docker rmi";
      dlog = "docker logs";
      dlf = "docker logs -f";
      dexec = "docker exec -it";
      dprune = "docker system prune -af";

      # Go development shortcuts
      gob = "go build";
      gor = "go run";
      got = "go test";
      gotv = "go test -v";
      gott = "gotestsum";
      gom = "go mod";
      gomt = "go mod tidy";
      gomi = "go mod init";
      gofmt = "goimports -w";
      golint = "golangci-lint run";
      gorel = "goreleaser release --snapshot --clean";
      govuln = "govulncheck ./...";

      # Cobra CLI development shortcuts
      cobra = "cobra-cli";
      cobinit = "cobra-cli init";
      cobadd = "cobra-cli add";
      cobgen = "cobra-cli generate";
      # Quick CLI project setup
      clinit = "cobra-cli init --pkg-name";
      # Build and test CLI in one command
      clitest = "go build -o ./bin/$(basename $PWD) && ./bin/$(basename $PWD)";
      # Install CLI locally for testing
      cliinstall = "go install .";

      # Better alternatives
      cat = "bat";
      grep = "rg";
      find = "fd";
      ps = "procs";
      du = "dust";
      top = "bottom";

      # Dirs
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "......" = "cd ../../../../..";

      # Quick navigation with zoxide
      zi = "zoxide query -i";
    };

    initContent = ''
      # Auto-load SSH keys
      if [[ -z "$SSH_AUTH_SOCK" || ! -S "$SSH_AUTH_SOCK" ]]; then
          eval "$(ssh-agent -s)" >/dev/null
          ssh-add
      fi

      # Custom commit function
      _cc() {
        echo "Type (feat, fix, chore, etc.):"
        read type
        echo "Scope (optional):"
        read scope
        echo "Message:"
        read msg

        if [[ -n "$scope" ]]; then
          git commit -m "$type($scope): $msg"
        else
          git commit -m "$type: $msg"
        fi
      }

      # Extract any archive
      extract() {
        if [ -f "$1" ]; then
          case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      # Make directory and cd into it
      mkcd() {
        mkdir -p "$@" && cd "$_"
      }

      # Quick find and edit
      fe() {
        local file
        file=$(fd --type f --hidden --exclude .git | fzf --preview="bat --color=always --style=numbers --line-range=:500 {}") && [ -f "$file" ] && $EDITOR "$file"
      }

      # Git worktree quick navigation
      gwcd() {
        local worktree
        worktree=$(git worktree list | fzf | awk '{print $1}')
        [ -n "$worktree" ] && cd "$worktree"
      }

      # Better history search
      bindkey '^R' history-incremental-search-backward
      bindkey '^S' history-incremental-search-forward

      # Additional zsh options
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      setopt PUSHD_SILENT
      setopt NO_CORRECT
      setopt EXTENDED_GLOB
      setopt NO_CASE_GLOB
      setopt NUMERIC_GLOB_SORT

      # AI-powered commit message (requires claude CLI)
      commit() {
        local staged
        staged=$(git diff --staged)
        if [[ -z "$staged" ]]; then
          echo "Nothing staged. Run: git add <files>" >&2
          return 1
        fi
        echo "$staged" | claude -p \
          "Analyse this git diff and output a single ready-to-run git commit command.
Rules:
- Conventional Commits: type(scope): subject
- type: feat|fix|docs|refactor|chore|ci|style|test|perf
- scope: directory or module name (not a filename), omit if cross-cutting
- subject: imperative mood, lowercase, no period, max 72 chars
- add a second -m body only if the WHY is non-obvious from the diff
- output ONLY the git commit command, nothing else"
      }

      # AI-powered PR description (requires claude CLI)
      # Usage: pr-desc [base-branch]  (default: main)
      pr-desc() {
        local base=''${1:-main}
        local content
        content=$(git log "$base..HEAD" --oneline 2>/dev/null && git diff "$base..HEAD" 2>/dev/null)
        if [[ -z "$content" ]]; then
          echo "No commits ahead of $base" >&2
          return 1
        fi
        echo "$content" | claude -p \
          "Write a GitHub PR description for these changes.
Structure (markdown):
## What
One paragraph. High-level overview — not file-by-file, not a commit list.

## Why
One paragraph. The problem solved or goal achieved.

## Notable changes
3-6 bullets max. Only non-obvious decisions or risk areas. Omit section if nothing remarkable.

Rules: no changelog, no commit list, no boilerplate. Output only the markdown."
      }

    '';
  };
}
