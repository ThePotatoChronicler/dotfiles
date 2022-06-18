function hsl_to_rgb --description 'Converts HSL color to RGB color'
    # Source : https://en.wikipedia.org/wiki/HSL_and_HSV#HSL_to_RGB

    # Arguments
    for i in (seq (count $argv))
        if test $argv[$i] = '-h'
            set hex 1
            set -e argv[$i]
            break
        end
    end

    if test -n "$argv[1]"
        set H (math "abs($argv[1] % 360)")
    else
        set H (random 0 360)
    end

    if test -n "$argv[2]"
        set S $argv[2]
    else
        set S 1
    end

    if test -n "$argv[3]"
        set L $argv[3]
    else
        set L 0.5
    end
    # Arguments parsed

    # Math scawy
    set C (math "(1 - abs(2 * $L - 1)) * $S")
    set Hd (math "$H / 60")
    set X (math "$C * (1 - abs($Hd % 2 - 1))")

    # Setting beforehand, so it doesn't need to be repeated
    set R1 0
    set G1 0
    set B1 0

    switch (math "floor($Hd)")
        case 0
            set R1 $C
            set G1 $X
        case 1
            set R1 $X
            set G1 $C
        case 2
            set G1 $C
            set B1 $X
        case 3
            set G1 $X
            set B1 $C
        case 4
            set R1 $X
            set B1 $C
        case 5
            set R1 $C
            set B1 $X
    end

    set m (math "$L - $C / 2")
    if test -z "$hex"
        printf "%d %d %d" (math "floor(($R1 + $m) * 255)") (math "floor(($G1 + $m) * 255)") (math "floor(($B1 + $m) * 255)")
    else
        printf "%02x%02x%02x" (math "floor(($R1 + $m) * 255)") (math "floor(($G1 + $m) * 255)") (math "floor(($B1 + $m) * 255)")
    end
end
