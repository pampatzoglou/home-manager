{ config, pkgs, lib, ... }:

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

      shell = {
        format = "[$indicator]($style) ";
        disabled = false;
      };

      cmd_duration = {
        min_time = 1000;
        format = "⏱ [$duration]($style)";
        style = "yellow";
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
