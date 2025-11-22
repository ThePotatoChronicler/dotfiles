const podman_image = "quay.io/podman/stable:v5.6"

def get-git-toplevel []: nothing -> string {
  git rev-parse --show-toplevel
  | complete
  | if $in.exit_code == 0 {
    $in.stdout
  } else {
    error make {
      msg: "Current directory is not a git repository"
    }
  }
}

def run-pinp-container [
  opts: record<pinp_volume: string>
]: nothing -> string {
  (
    podman run
      -d
      --rm
      --user podman
      $"--mount=type=volume,src=($opts.pinp_volume),dst=/mnt/pinp"
      -v forgejo-exec-pinp-storage:/home/podman/.local/share/containers
      --device /dev/fuse
      --device /dev/net/tun
      --security-opt unmask=/proc/sys
      --
      $podman_image
      podman system service -t0 unix:///mnt/pinp/podman.sock
  ) | complete
    | if $in.exit_code == 0 {
      $in.stdout
    } else {
      error make {
        msg: $"Failed to create PINP container: \"($in.stderr)\""
      }
    }
}

def workflows-completion []: nothing -> list<string> {
  glob **/*.{yml,yaml}
  | path relative-to (pwd)
}

# Runs forgejo-runner exec in a container
export def main [
  --workflows (-W): path@workflows-completion #workflow file(s) (default "./.forgejo/workflows/")
  --var: record = {} # variables to make available to actions with optional value
  --secret: record = {} # secret to make available to actions with optional value
] {

  let git_toplevel = get-git-toplevel

  let pinp_volume = podman volume create --opt device=tmpfs --opt type=tmpfs --opt o=uid=1000,gid=1000

  let pinp_container = run-pinp-container { pinp_volume: $pinp_volume }

  (
    podman run
        -ti
        --rm
        $"--mount=type=volume,src=($pinp_volume),dst=/mnt/pinp"
        $"--mount=type=bind,ro,dst=/mnt/repository,src=($git_toplevel)"
        --env DOCKER_HOST=unix:///mnt/pinp/podman.sock
        --workdir /mnt/repository
        data.forgejo.org/forgejo/runner:11
        bash -c $"
            until [[ -a /mnt/pinp/podman.sock ]]; do
                sleep 0.05s
            done

            forgejo-runner \\
                exec \\
                    --env CONTAINER_HOST=unix:///var/run/docker.sock \\
                    --directory /mnt/repository \\
                    --container-daemon-socket=unix:///mnt/pinp/podman.sock \\
                \"$@\"
        " bash
        ...(if $workflows != null {[ --workflows $workflows ]})
        ...($var | items {|key, val| [--var (match ($val | describe) {
          "nothing" => $key
          "string" => $"($key)=($val)"
          $type => { error make { msg: $"Unsupported type ($type)" } }
        })]} | flatten)
        ...($secret | items {|key, val| [--secret (match ($val | describe) {
          "nothing" => $key
          "string" => $"($key)=($val)"
          $type => { error make { msg: $"Unsupported type ($type)" } }
        })]} | flatten)
  )

  podman exec -- $pinp_container bash -c "
      export CONTAINER_HOST=unix:///mnt/pinp/podman.sock
      {
          podman image ls --filter dangling=true --format '{{.Id}}'
          podman image ls --filter 'reference=localhost/*' --format '{{.Id}}' 
      } | xargs -r -- podman image rm
  " err> /dev/null

  podman kill -- $pinp_container err> /dev/null

  podman volume rm -f -- $pinp_volume err> /dev/null
}
