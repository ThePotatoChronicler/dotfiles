function run-forgejo-exec \
    -d "Runs forgejo-runner exec in a container"

    set -l podman_image quay.io/podman/stable:v5.6

    set -l git_toplevel (git rev-parse --show-toplevel 2> /dev/null)
    or begin
        echo "Current directory is not a git repository"
        return 1
    end

    set -l pinp_volume (
        podman volume create \
            --opt device=tmpfs --opt type=tmpfs --opt o=uid=1000,gid=1000
    )

    set -l pinp_container (
        podman run \
            -d \
            --rm \
            --user podman \
            --mount=type=volume,src=$pinp_volume,dst=/mnt/pinp \
            -v forgejo-exec-pinp-storage:/home/podman/.local/share/containers \
            --device /dev/fuse \
            --device /dev/net/tun \
            --security-opt unmask=/proc/sys \
            $podman_image \
            podman system service -t0 unix:///mnt/pinp/podman.sock
    )
    or begin
        echo "Failed to create PINP container"
        return 1
    end

    podman run \
        -ti \
        --rm \
        --mount=type=volume,src=$pinp_volume,dst=/mnt/pinp \
        --mount=type=bind,ro,dst=/mnt/repository,src=$git_toplevel \
        --env DOCKER_HOST=unix:///mnt/pinp/podman.sock \
        --workdir /mnt/repository \
        data.forgejo.org/forgejo/runner:11 \
        bash -c "
            until [[ -a /mnt/pinp/podman.sock ]]; do
                sleep 0.05s
            done

            forgejo-runner \
                exec \
                    --env CONTAINER_HOST=unix:///var/run/docker.sock \
                    --directory /mnt/repository \
                    --container-daemon-socket=unix:///mnt/pinp/podman.sock \
                $argv
        "

    podman exec $pinp_container bash -c "
        export CONTAINER_HOST=unix:///mnt/pinp/podman.sock
        {
            podman image ls --filter dangling=true --format '{{.Id}}'
            podman image ls --filter 'reference=localhost/*' --format '{{.Id}}' 
        } | xargs -r -- podman image rm
    " >/dev/null

    podman kill $pinp_container >/dev/null

    podman volume rm -f $pinp_volume >/dev/null
end
