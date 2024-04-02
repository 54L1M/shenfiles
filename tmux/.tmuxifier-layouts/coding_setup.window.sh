# window 0
new_window "shell"
run_cmd "workon fara"
split_h 50
select_pane 0

# window 1
new_window "code"
run_cmd "workon fara"
run_cmd "nvim ."

# window 2
new_window "git"
run_cmd "lazygit"
