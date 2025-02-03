# window 0
new_window "code"
run_cmd "workon ats"
run_cmd "source .env"
run_cmd "clear"
run_cmd "nvim ."

# window 1
new_window "shell"
run_cmd "workon ats"
run_cmd "source .env"
run_cmd "clear"

# window 2
new_window "server"
run_cmd "workon ats"
run_cmd "source .env"
run_cmd "clear"

# window 3
new_window "misc"
run_cmd "workon ats"
run_cmd "source .env"
run_cmd "clear"
