{ ... }:

{
  # === Starship config ===
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;

      format = "$directory$git_branch$git_status$character";
      right_format = "$kubernetes$docker_context$cmd_duration";

      directory = {
        truncation_length = 4;
        truncate_to_repo = false;
      };

      git_branch = {
        symbol = "⎇  ";
        truncation_length = 30;
        format = "on [$symbol($branch)]($style) ";
        style = "bold cyan";
      };

      git_status = {
        staged = "[+](green)";
        untracked = "[?](red)";
        modified = "[*](yellow)";
        deleted = "[✘](red)";
        renamed = "[»](blue)";
        ahead = "⇡";
        behind = "⇣";
        diverged = "⇕";
        disabled = false;
      };

      terraform = {
        format = "[🏗️ $workspace]($style) ";
        style = "bold purple";
        disabled = false;
      };

      aws = {
        format = "[☁️  $profile($region)]($style) ";
        style = "bold yellow";
        disabled = false;
        symbol = "☁️  ";
      };

      kubernetes = {
        format = "[k8s: $context( \\($namespace\\))]($style)";
        disabled = false;
        style = "blue bold";
      };

      docker_context = {
        format = "[🐳 $context]($style) ";
        style = "blue bold";
        disabled = false;
      };

      env_var = {
        variable = "ENV";
        default = "";
        format = "[$env_value]($style) ";
        style = "purple";
      };

      python = {
        symbol = "🐍 ";
        format = "[$symbol$virtualenv]($style) ";
        style = "yellow";
        python_binary = "python3";
        disabled = false;
      };

      golang = {
        symbol = "🐹 ";
        format = "[$symbol($version)]($style) ";
        style = "cyan bold";
        disabled = false;
      };

      nodejs = {
        format = "⬢ [$version]($style) ";
        style = "green";
        disabled = false;
      };

      rust = {
        symbol = "🦀 ";
        format = "[$symbol$version]($style) ";
        style = "red bold";
      };

      character = {
        success_symbol = "[✔](bold green)";
        error_symbol = "[✗](bold red)";
      };

      status = {
        disabled = false;
        symbol = "✖";
        format = "[$symbol $status]($style) ";
        style = "bold red";
      };

      shell = {
        format = "[$indicator]($style) ";
        disabled = false;
      };

      cmd_duration = {
        min_time = 1000;
        format = "⏱ [$duration]($style)";
        style = "yellow";
      };

      git_metrics = {
        disabled = false;
        added_style = "bold green";
        deleted_style = "bold red";
        format = "[+$added]($added_style)/[-$deleted]($deleted_style) ";
      };

      memory_usage = {
        disabled = false;
        threshold = 75;
        format = "via $symbol [\${ram}]($style) ";
        symbol = "🐏";
        style = "bold dimmed white";
      };

      gcloud = {
        format = "[☁️  $project(\\($region\\))]($style) ";
        style = "bold yellow";
        disabled = false;
      };

      hostname = {
        ssh_only = true;
        format = "[$hostname]($style) ";
        style = "green";
      };

      # Additional useful modules
      helm = {
        format = "[⎈ $version]($style) ";
        style = "bold white";
        disabled = false;
      };

      pulumi = {
        format = "[🛥 $stack]($style) ";
        style = "bold blue";
        disabled = false;
      };

      nix_shell = {
        format = "[❄️  $state( \\($name\\))]($style) ";
        style = "bold blue";
        disabled = false;
      };
    };
  };
}
