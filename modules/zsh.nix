{ config, pkgs, lib, ... }:

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

      # Docker shortcuts
      d = "docker";
      dc = "docker-compose";
      dps = "docker ps";
      di = "docker images";
      drm = "docker rm";
      drmi = "docker rmi";
      dlog = "docker logs";
      dexec = "docker exec -it";

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
      eval "$(ssh-agent -s)" >/dev/null
      chmod 600 ~/.ssh/id_ed25519_sk_rk_* 2>/dev/null
      for key in ~/.ssh/id_ed25519_sk_rk_*; do
          if [[ "$key" != *.pub ]]; then
              ssh-add "$key" 2>/dev/null
          fi
      done

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
