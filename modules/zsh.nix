{ ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
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
      cc = ''noglob _cc'';

      # Git
      gc = "git commit -m";
      gca = "git commit -a -m";
      gp = "git push origin HEAD";
      gpu = "git pull origin";
      gst = "git status";
      gs = "git status";
      glog = "git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit";
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
      # SSH agent and keys are managed by macOS launchd + brew openssh
      # AddKeysToAgent=yes in SSH config will auto-load keys as needed

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
      setopt CORRECT
      setopt EXTENDED_GLOB
      setopt NO_CASE_GLOB
      setopt NUMERIC_GLOB_SORT

      # Initialize starship prompt
      eval "$(starship init zsh)"
      eval "$(zoxide init zsh)"
    '';
  };
}
