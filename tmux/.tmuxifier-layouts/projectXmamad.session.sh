session_root "~/Documents/0xshen/amper/XMamad/"

if initialize_session "projectXmamad"; then

  new_window "shell"
  run_cmd "workon dj"
  split_h 50
  run_cmd "workon dj"
  select_pane 0

  new_window "code"
  run_cmd "workon dj"
  run_cmd "nvim ."

  new_window "git"
  run_cmd "lg"

  select_window 0

fi

finalize_and_go_to_session
