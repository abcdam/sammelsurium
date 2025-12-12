. $(get-posher)
_g2_get_registry() {
  local RETVAL=0
  local dir="${G2_CONF_DIR:-/tmp}"
  local registry_name=.g2_paths
  local registry_file="$dir/$registry_name"

  [ -f "$registry_file" ] || RETVAL=1
  [ $RETVAL -eq 0 ]             \
    && printf '%s' "$registry_file"   \
    || printf "registry '%s' not found in dir 'G2_CONF_DIR=%s'" "$registry_name" "$dir"
  return $RETVAL
}

g2() {
  local RETVAL=0; local target_key="${1:-}"
  local registry_file target_path err_msg
  if [ -z "$target_key" ]; then
    RETVAL=1; err_msg='Usage: g2 <key>'
  else
    registry_file=$(_g2_get_registry) || RETVAL=$?
    if [ $RETVAL -ne 0 ]; then
      err_msg="$registry_file"
    else
      target_path=$(awk -v k="$target_key" '$1==k {print $2}' "$registry_file")
      [ -n "$target_path" ] && target_path="${target_path/#\~/$HOME}" || RETVAL=1
      if [ $RETVAL -ne 0 ]; then
        err_msg="key '$target_key' not found in registry"
      elif [ -d "$target_path" ]; then
        cd "$target_path" || RETVAL=$?
        [ $RETVAL -ne 0 ] && err_msg="unable to access '$target_path' for key '$target_key'"
      else
        RETVAL=1; err_msg="target '$target_path' not a dir (key: '$target_key')"
      fi
    fi
  fi
  [ -n "${err_msg:-}" ] && posher yap hint "$err_msg"
  return $RETVAL
}

_g2_completions() {
    local registry_file cur_word keys
    if registry_file=$(_g2_get_registry); then
      cur_word="${COMP_WORDS[COMP_CWORD]}"
      mapfile -t keys < <(awk '{print $1}' "$registry_file")
      COMPREPLY=( $(compgen -W "${keys[*]}" -- "$cur_word") )
    fi
}
_g2_list() {
  local RETVAL=0; local registry_file full_prompt prompt_top text
  registry_file=$(_g2_get_registry) || RETVAL=$?
  if [ $RETVAL -eq 0 ]; then
    text="${READLINE_LINE:0:READLINE_POINT}"
    awk -v prefix="${text##* }" '
        $1 ~ "^"prefix {
            printf "%-15s  %s\n", $1, $2
        }
    ' "$registry_file"
  else
    posher yap hint "$registry_file"
  fi
  full_prompt="${PS1@P}"
  if [[ "$full_prompt" == *$'\n'* ]]; then
    prompt_top="${full_prompt%$'\n'*}"
    printf "%s\n" "$prompt_top"
  fi
  return $RETVAL
}
bind -x '"\C-g":_g2_list'
complete -F _g2_completions g2
