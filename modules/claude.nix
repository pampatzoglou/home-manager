{ lib, ... }:

# Claude AI Assistant Configuration Module
#
# This module manages Claude's configuration files through home-manager.
# It deploys personal coding preferences, skills, and configuration templates.
#
# Key Features:
# - Auto-discovery: All .md files and directories in agentic/claude/skills/ are automatically deployed
# - Supports both flat .md files and skill directories with multiple files
# - Source-based: Files are sourced from agentic/ directory for easy editing
# - Git-aware: Only tracked or staged files are deployed (Nix flake requirement)
#
# Skill Structure Support:
# - Flat files: skills/code-review.md -> ~/.claude/skills/code-review.md
# - Directories: skills/terraform/ -> ~/.claude/skills/terraform/ (recursive)
#
# Usage:
# 1. Add/edit files in agentic/claude/skills/
# 2. Stage in git: git add agentic/claude/skills/new-skill.md
# 3. Deploy: home-manager switch --flake . --impure
#
# Deployed Files:
# - ~/.claude/CLAUDE.md              - Personal coding preferences
# - ~/.claude/skills/*.md             - Auto-discovered flat skill files
# - ~/.claude/skills/*/               - Auto-discovered skill directories
# - ~/.claude/agents/.gitkeep         - Placeholder for agents directory
#
# Note: settings.json is NOT managed by this module to avoid overwriting
# existing hooks configuration. See agentic/claude/settings.json.template

let
  # Automatically discover all files and directories in the skills directory
  skillsDir = ../agentic/claude/skills;
  skillEntries = builtins.readDir skillsDir;

  # Filter to only .md files and directories, excluding system files
  validEntries = lib.filterAttrs (name: type:
    (type == "regular" && lib.hasSuffix ".md" name)
    || (type == "directory" && !lib.hasPrefix "." name)) skillEntries;

  # Create deployment mappings for both files and directories
  # Files: Direct copy
  # Directories: Recursive copy to preserve structure
  skillMappings = lib.mapAttrs' (name: type:
    lib.nameValuePair ".claude/skills/${name}" (if type == "directory" then {
      source = "${skillsDir}/${name}";
      recursive = true;
    } else {
      source = "${skillsDir}/${name}";
    })) validEntries;

in {

  home.file = {
    # Personal coding style and preferences
    ".claude/CLAUDE.md" = { source = ../agentic/claude/CLAUDE.md; };

    # Placeholder for agents directory (alternative to skills)
    ".claude/agents/.gitkeep" = { text = ""; };
  }
    // skillMappings; # Merge auto-discovered skill files and directories into home.file
}
