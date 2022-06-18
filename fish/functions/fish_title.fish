function fish_title
    if set -q argv[1]
        echo "$argv"
    else
        echo "<><" (string replace "$HOME" '~' "$PWD")
    end
end
