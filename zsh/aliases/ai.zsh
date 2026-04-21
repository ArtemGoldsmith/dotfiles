# vim:ft=zsh

## claude
alias cc='claude --dangerously-skip-permissions'
alias ccr='claude --resume --dangerously-skip-permissions'

# start claude inside the Obsidian vault (picks up vault's CLAUDE.md)
# usage: occ              — new session in vault
#        occ --resume     — resume previous session in vault
function occ() {
  cd ~/"The Vault" && claude --dangerously-skip-permissions "$@"
}

## codex
alias co='codex --full-auto'
