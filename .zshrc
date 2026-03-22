# ------------------------------------------
# 0) P10k instant prompt must be first (no output before this)
[[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]] \
  && source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"

# Only do heavy init in interactive shells
[[ -o interactive ]] || return

# ------------------------------------------
# 1) Locale
export LC_ALL=en_US.UTF-8

# ------------------------------------------
# 2) Homebrew (Apple Silicon path, Intel fallback)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ------------------------------------------
# 3) PATH
typeset -U path PATH
path=("$HOME/.local/bin" $path)

# ------------------------------------------
# 4) direnv
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# ------------------------------------------
# 5) Oh-My-Zsh + plugins
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  git
  yarn
  zsh-autosuggestions
  zsh-syntax-highlighting
  history-substring-search
  you-should-use
)
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# p10k config
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# ------------------------------------------
# 6) NVM — lazy-load (shimming node/npm/npx avoids eager sourcing)
export NVM_DIR="$HOME/.nvm"

_load_nvm() {
  unset -f nvm node npm npx
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
}

nvm()  { _load_nvm; nvm  "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm  "$@"; }
npx()  { _load_nvm; npx  "$@"; }

# ------------------------------------------
# 7) Aliases
alias dc='docker compose'

# ------------------------------------------
# 8) Local overlay (unversioned — work or machine-specific config)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
