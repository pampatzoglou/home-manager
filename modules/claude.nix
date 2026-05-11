{ lib, ... }:

# Claude AI Assistant Configuration Module
#
# Auto-discovers all directories in agentic/claude/skills/ and deploys them
# recursively to ~/.claude/skills/. Only git-tracked files are visible to Nix flakes.
#
# To add a skill: create agentic/claude/skills/<name>/SKILL.md, git add, task switch.
#
# Note: settings.json is NOT managed here — edit ~/.claude/settings.json manually.

let
  # Automatically discover all files and directories in the skills directory
  skillsDir = ../agentic/claude/skills;
  skillEntries = builtins.readDir skillsDir;

  # Filter to only directories (all skills are now directory-based), excluding hidden entries
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
