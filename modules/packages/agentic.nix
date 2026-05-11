{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # AI coding assistants
    claude-code # Anthropic's Claude CLI

    # Local and multi-provider inference
    ollama # Run LLMs locally (llama3, mistral, etc.)
    llama-cpp # Inference of LLaMA and other models in pure C/C++
    llm # CLI for OpenAI, Anthropic, Ollama, OpenRouter, and more
  ];
}
