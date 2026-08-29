{ pkgs, ... }:

{
  # Claude Code is deliberately NOT installed from nixpkgs. It self-updates in
  # place under ~/.local/share/claude/versions/, which an immutable store path
  # cannot do, and ~/.local/bin (see modules/zsh.nix) shadows ~/.nix-profile/bin
  # anyway — so a nixpkgs claude-code is dead weight that only ever lags behind.
  home.packages = with pkgs; [
    # Local and multi-provider inference
    ollama # Run LLMs locally (llama3, mistral, etc.)
    llama-cpp # Inference of LLaMA and other models in pure C/C++
    llm # CLI for OpenAI, Anthropic, Ollama, OpenRouter, and more
  ];
}
