{ lib, ... }:

# Claude AI Assistant Configuration Module
#
# This module manages Claude's configuration files through home-manager.
# It deploys personal coding preferences, skills, and configuration templates.
#
# Key Features:
# - Auto-discovery: All .md files in agentic/claude/skills/ are automatically deployed
# - Source-based: Files are sourced from agentic/ directory for easy editing
# - Git-aware: Only tracked or staged files are deployed (Nix flake requirement)
#
# Usage:
# 1. Add/edit files in agentic/claude/skills/
# 2. Stage in git: git add agentic/claude/skills/new-skill.md
# 3. Deploy: home-manager switch --flake . --impure
#
# Deployed Files:
# - ~/.claude/CLAUDE.md           - Personal coding preferences
# - ~/.claude/skills/*.md          - Auto-discovered skill files
# - ~/.claude/agents/.gitkeep      - Placeholder for agents directory
#
# Note: settings.json is NOT managed by this module to avoid overwriting
# existing hooks configuration. See agentic/claude/settings.json.template

let
  # Automatically discover all files in the skills directory
  skillsDir = ../agentic/claude/skills;

  # Read all files in the skills directory
  skillFiles = builtins.readDir skillsDir;

  # Filter to only .md files and create deployment mappings
  # This creates an attribute set like:
  # { ".claude/skills/code-review.md" = { source = ...; }; ... }
  skillMappings = lib.mapAttrs' (name: type:
    lib.nameValuePair ".claude/skills/${name}" {
      source = "${skillsDir}/${name}";
    })
    (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name)
      skillFiles);

in {

  home.file = {
    # Personal coding style and preferences
    ".claude/CLAUDE.md" = { source = ../agentic/claude/CLAUDE.md; };

    # Placeholder for agents directory (alternative to skills)
    ".claude/agents/.gitkeep" = { text = ""; };
  } // skillMappings; # Merge auto-discovered skill files into home.file
}
