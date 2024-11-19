#!/bin/zsh

# Function to update the prompt
update_prompt() {
    local on_env_id="$1"

    if [ -n "${VIRTUAL_ENV:-}" ] ; then
	on_env_id="${on_env_id}+$(basename $VIRTUAL_ENV)"
    fi

    # Remove any existing (on-env: ...) from PROMPT
    PROMPT="${PROMPT//\(on-env: *)}"

    # Append the new (on-env: ...) to PROMPT
    PROMPT="(on-env: $on_env_id)${PROMPT}"
}

# Function to be added to precmd_functions
set_envs_prompt_precmd() {
    update_prompt "$ON_ENV_ID"
}

# Check if an env ID was provided
if [ $# -eq 0 ]; then
    echo "Usage: source $0 <env-id>"
    return 1
fi

# Store the credential ID in a global variable
ON_ENV_ID="$1"

# Update the prompt immediately
update_prompt "$ON_ENV_ID"

# Check if precmd is already defined as a function
if (( ${+functions[precmd]} )); then
    # echo "Existing precmd function found. Adding our function to precmd_functions array."
    precmd_functions+=set_envs_prompt_precmd
else
    # If precmd isn't defined, we can define it directly
    precmd() {
        set_envs_prompt_precmd
    }
fi

# If precmd_functions array exists, ensure our function is in it
if [[ -n ${precmd_functions} ]]; then
    if (( ${precmd_functions[(I)set_envs_prompt_precmd]} == 0 )); then
        precmd_functions+=set_envs_prompt_precmd
    fi
else
    # If precmd_functions doesn't exist, create it with our function
    precmd_functions=(set_envs_prompt_precmd)
fi

# echo "Prompt update function installed."
