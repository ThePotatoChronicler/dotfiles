const podman_image = "quay.io/podman/stable:v5.8"

def box_variants [] {
  [
    { value: "base", style: { fg: cyan } }
    { value: "javascript", style: { fg: yellow } }
    { value: "python", style: { fg: blue } }
  ]
}

def run-pinp-container [
  opts: record<pinp_volume: string>
]: nothing -> string {
  (
    podman run
      -d
      --user podman
      $"--mount=type=volume,src=($opts.pinp_volume),dst=/mnt/pinp"
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

# Runs boxed environments
export def main [
  --variant: string@"box_variants" = "base" # Image variant
  --mount-cwd # Mounts current working directory
  --no-create # Forbids creation of new boxes
  --no-podman # Do not connect a podman runner
  --rm # Create a temporary box
  box_name: string
]: nothing -> nothing {
  const podman_image = "quay.io/podman/stable:v5.6"

  let container_name = $"box_($box_name)"

  let container_exists = (
    ^podman container exists -- $container_name
    | complete
    | get exit_code
    | $in == 0
  )

  if $container_exists {
    let container_status = (podman container inspect --format="{{ .State.Status }}" $container_name)

    match $container_status {
      "exited" => {
        podman container start -ia -- $container_name
      }
      "running" => {
        podman container exec -ti -- $container_name /proc/1/exe
      }
    }
  } else {
      if $no_create {
        echo "This container doesn't exist, and you've forbidden creating new ones"
        return 1
      }

      let pinp_volume = if not $no_podman {
        podman volume create --opt device=tmpfs --opt type=tmpfs --opt o=uid=1000,gid=1000
      }

      let pinp_container = if not $no_podman {
        run-pinp-container { pinp_volume: $pinp_volume }
      }

      (
        podman run
          -ti
          --env TERM
          --env COLORTERM
          --name $container_name
          ...(if $mount_cwd {[
            "--mount=type=bind,src=.,dst=/mnt/cwd"
            "--workdir=/mnt/cwd"
            "--userns=keep-id:uid=1000,gid=1000"            
          ]})
          ...(if $rm {[--rm]})
          ...(if (not $no_podman) {[
            --requires=($pinp_container)
            $"--mount=type=volume,src=($pinp_volume),dst=/mnt/pinp"
            --env CONTAINER_HOST=unix:///mnt/pinp/podman.sock
          ]})
          --
          $"codeberg.org/potatochronicler/dotfiles/containers/($variant):latest"
      )

      if not $no_podman {
        podman stop $pinp_container
      }
  }
}
