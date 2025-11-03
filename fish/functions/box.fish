function box \
    --description "Runs boxed environments"

    argparse --min-args 1 --max-args 1 -S "v/variant=" /rm \
        -- $argv
    or return

    if set -q _flag_variant[1]
        set -f variant $_flag_variant[1]
    else
        set -f variant base
    end

    set -f container_name "box_$argv[1]"

    if podman container exists $container_name
        set -l container_status \
            (podman container inspect --format="{{ .State.Status }}" $container_name)

        switch $container_status
            case exited
                podman container start -ia -- $container_name
            case running
                podman container attach -- $container_name
        end
    else
        podman run \
            -ti \
            (set -q _flag_rm && printf "--rm") \
            --env TERM \
            --env COLORTERM \
            --name $container_name \
            -- \
            "codeberg.org/potatochronicler/dotfiles/containers/$variant:latest"
    end
end
