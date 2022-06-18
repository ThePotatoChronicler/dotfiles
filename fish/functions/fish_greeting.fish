#!/usr/bin/env fish
function fish_greeting
    command -q fortune && fortune
end
