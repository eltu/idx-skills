#!/usr/bin/env bash
set -euo pipefail

# Enable colors only when output is a terminal.
if [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_BOLD='\033[1m'
  C_BLUE='\033[34m'
  C_GREEN='\033[32m'
  C_YELLOW='\033[33m'
  C_RED='\033[31m'
else
  C_RESET=''
  C_BOLD=''
  C_BLUE=''
  C_GREEN=''
  C_YELLOW=''
  C_RED=''
fi

print_info() {
  echo -e "${C_BLUE}[INFO]${C_RESET} $1"
}

print_ok() {
  echo -e "${C_GREEN}[OK]${C_RESET} $1"
}

print_warn() {
  echo -e "${C_YELLOW}[WARN]${C_RESET} $1"
}

print_error() {
  echo -e "${C_RED}[ERROR]${C_RESET} $1" >&2
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SKILL_DIR="$SCRIPT_DIR/skills/idx-search"
SKILL_NAME="idx-search"

if [[ ! -f "$SOURCE_SKILL_DIR/SKILL.md" ]]; then
  print_error "Canonical skill not found at: $SOURCE_SKILL_DIR"
  exit 1
fi

usage() {
  cat <<'EOF'
==================== IDX SKILL INSTALLER ====================
Usage
  ./install-skills.sh [copilot|claude|cursor]

Without an argument, the script asks which tool to install.
Installs into the user's HOME directory to be available across all projects.

Examples
  ./install-skills.sh copilot
  ./install-skills.sh claude
  ./install-skills.sh cursor
=============================================================
EOF
}

choose_tool() {
  echo -e "${C_BOLD}Choose the tool to install the skill:${C_RESET}"
  echo "  1) copilot"
  echo "  2) claude"
  echo "  3) cursor"
  printf "${C_BOLD}> ${C_RESET}"
  read -r option

  case "$option" in
    1) CHOSEN_TOOL="copilot" ;;
    2) CHOSEN_TOOL="claude" ;;
    3) CHOSEN_TOOL="cursor" ;;
    *)
      print_error "Invalid option: $option"
      exit 1
      ;;
  esac
}

install_copilot() {
  local target_dir="$HOME/.copilot/skills/$SKILL_NAME"
  print_info "Installing for Copilot..."
  print_info "Target: $target_dir"
  mkdir -p "$target_dir"
  cp -R "$SOURCE_SKILL_DIR"/. "$target_dir"/
  print_ok "Installed for Copilot at: $target_dir"
}

configure_claude_permissions() {
  local settings_file="$HOME/.claude/settings.json"
  local permission="Bash(idx *)"

  if ! command -v jq &>/dev/null; then
    print_warn "jq not found — skipping automatic permission setup."
    print_warn "Add manually to $settings_file: \"$permission\""
    return
  fi

  if [[ ! -f "$settings_file" ]]; then
    mkdir -p "$(dirname "$settings_file")"
    echo '{"permissions":{"allow":[]}}' > "$settings_file"
    print_info "Created $settings_file"
  fi

  if jq -e --arg p "$permission" '.permissions.allow | index($p)' "$settings_file" > /dev/null 2>&1; then
    print_info "Permission '$permission' already configured."
  else
    local tmp
    tmp=$(mktemp)
    jq --arg p "$permission" '.permissions.allow += [$p]' "$settings_file" > "$tmp"
    mv "$tmp" "$settings_file"
    print_ok "Added permission '$permission' to $settings_file"
  fi
}

install_claude() {
  local target_dir="$HOME/.claude/skills/$SKILL_NAME"
  print_info "Installing for Claude..."
  print_info "Target: $target_dir"
  mkdir -p "$target_dir"
  cp -R "$SOURCE_SKILL_DIR"/. "$target_dir"/
  configure_claude_permissions
  print_ok "Installed for Claude at: $target_dir"
}

install_cursor() {
  local target_dir="$HOME/.cursor/skills/$SKILL_NAME"

  print_info "Installing for Cursor..."
  print_info "Target: $target_dir"
  mkdir -p "$target_dir"
  cp -R "$SOURCE_SKILL_DIR"/. "$target_dir"/

  print_ok "Installed for Cursor at: $target_dir"
}

main() {
  local tool="${1:-}"

  echo -e "${C_BOLD}IDX Skill Installer${C_RESET}"
  print_info "Canonical source: $SOURCE_SKILL_DIR"

  if [[ "$tool" == "-h" || "$tool" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ -z "$tool" ]]; then
    print_warn "No tool provided as argument. Opening interactive selection."
    choose_tool
    tool="$CHOSEN_TOOL"
  fi

  case "$tool" in
    copilot) install_copilot ;;
    claude) install_claude ;;
    cursor) install_cursor ;;
    *)
      print_error "Invalid tool: $tool"
      usage
      exit 1
      ;;
  esac

  print_ok "Process completed successfully."
}

main "$@"
