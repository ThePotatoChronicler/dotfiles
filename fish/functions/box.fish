function box --wraps "podman run" \
    --description "Runs boxed environments"

    argparse --move-unknown --min-args 1 --max-args 1 -S \
        "/variant=&" \
        /name= \
        "/mount-cwd&" \
        "/no-create&" \
        -- $argv
    or return

    set -q _flag_name && begin
        echo "You may not set the container name using --name" >&2
        return 1
    end

    if set -q _flag_variant
        set -f variant $_flag_variant
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
        if set -q _flag_no_create
            echo "This container doesn't exist, and you've forbidden creating new ones"
            return 1
        end

        podman run \
            -ti \
            --env TERM \
            --env COLORTERM \
            --name $container_name \
            (set -q _flag_mount_cwd \
                && printf "%s\n" "--mount=type=bind,src=.,dst=/mnt/cwd" "--workdir=/mnt/cwd") \
            (set -q _flag_mount_cwd \
                && printf "%s\n" "--userns=keep-id:uid=1000,gid=1000") \
            $argv_opts \
            -- \
            "codeberg.org/potatochronicler/dotfiles/containers/$variant:latest"
    end
end
