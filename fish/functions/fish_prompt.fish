function fish_prompt --description 'Rainbow prompt :)'
    set -l HSL_TO_RGB "$__fish_config_dir/hsl_to_rgb/hsl_to_rgb"

    # Here so the other commands don't overwrite it
    set last_pipestatus $pipestatus

    # Changes prompt sign if you're roo
    if test "$USER" = root
        set prompt_sign '#'
    else
        set prompt_sign '$'
    end

    # Changes color of prompt sign if last command exited with a status other than 0
    if test 0 -eq $last_pipestatus[-1]
        set status_color "$fish_color_cwd"
    else
        set status_color "$fish_color_status"
    end

    # Sets the pipestatus string
    set pipestatus_string (__fish_print_pipestatus "[" "] " "|" (set_color $fish_color_status) \
                          (set_color --bold $fish_color_status) $last_pipestatus)

    # Replaces $HOME in $PWD with ~
    set pwdr (string replace "$HOME" '~' "$PWD")

    # Prints the starting bracket
    printf '%s[' (set_color white)

    # Checks if the variable is set, if not, sets it
    set -q RAINBOW_PROMPT || set -g RAINBOW_PROMPT (random)

    set -l CHANGE_LEVEL "2.2"

    # Prints the user's name
    for i in (string split '' $USER)
        set_color ( $HSL_TO_RGB $RAINBOW_PROMPT 1 0.5 )
        printf "$i"
        set RAINBOW_PROMPT (math "$RAINBOW_PROMPT + $CHANGE_LEVEL") # Change the number to set how fast the color changes
    end

    # Prints a colored @
    printf "%s@%s" (set_color bryellow) (set_color brcyan)

    for i in (string split '' (prompt_hostname))
        set_color ( $HSL_TO_RGB $RAINBOW_PROMPT 1 0.5 )
        printf "$i"
        set RAINBOW_PROMPT (math "$RAINBOW_PROMPT + $CHANGE_LEVEL") # Change the number to set how fast the color changes
    end

    # Prints the rest. kinda confusing with that large amount of formatting
    printf '%s] %s%s %s[%s] %s\f\r%s%s ' \
        (set_color white) \
        (set_color $fish_color_cwd) $pwdr (set_color brblack) (date +%T) "$pipestatus_string" \
        (set_color $status_color) $prompt_sign

    printf '%s' (set_color normal)
end
