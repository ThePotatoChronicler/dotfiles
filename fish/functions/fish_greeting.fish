#!/usr/bin/env fish
function fish_greeting
    if command -q pokemon-colorscripts
        pokemon-colorscripts -r --no-title
    else if command -q fortune
        fortune
    end
end
