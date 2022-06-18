function fish_right_prompt
    if test 0 -ne $status
        printf "%s<%s>%s<" (set_color FF0000) (set_color FF9900) (set_color FFFF00)
    end
end
