{ ... }:

# Claude AI Assistant Configuration Module
#
# Deploys personal preferences to ~/.claude/CLAUDE.md.
#
# Skills and persona slash commands are NOT deployed from this repo: they come
# from the `mentor` and `personas` Claude Code plugins (marketplace
# github:pampatzoglou/mentor). Deploying copies here as well made every skill
# load twice, with the two versions drifting apart.
#
# Note: settings.json is NOT managed here — edit ~/.claude/settings.json manually.
# Plugin enablement (`enabledPlugins`, `extraKnownMarketplaces`) lives there.

{
  home.file = {
    # Personal coding style and preferences
    ".claude/CLAUDE.md" = { source = ../agentic/claude/CLAUDE.md; };

    # Placeholder for agents directory (alternative to skills)
    ".claude/agents/.gitkeep" = { text = ""; };
  };
}
