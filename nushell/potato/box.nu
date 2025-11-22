def "nu-complete box variants" [] {
  [
    { value: "base", style: { fg: cyan } }
    { value: "javascript", style: { fg: yellow } }
    { value: "python", style: { fg: blue } }
  ]
}

# Runs boxed environments
export def main [
  --variant: string@"nu-complete box variants" = "base" # Image variant
  --mount-cwd # Mounts current working directory
  --no-create # Forbids creation of new boxes
  --no-podman # Do not connect a podman runner
  --rm # Create a temporary box
  box_name: string
]: nothing -> nothing {
  const podman_image = "quay.io/podman/stable:v5.6"

  let container_name = $"box_($box_name)"

  let container_exists = ^podman container exists -- $container_name
    | complete
    | get exit_code
    | $in == 0

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

      let pinp_constainer = if not $no_podman {
        # Create PINP container
      }

      (
        podman run
          -ti
          --env TERM
          --env COLORTERM
          --name $container_name
          ...(if $mount_cwd {[--mount=type=bind,src=.,dst=/mnt/cwd --workdir=/mnt/cwd]})
          ...(if $mount_cwd {[--userns=keep-id:uid=1000,gid=1000]})
          ...(if $rm {[--rm]})
          # ...(if (not $no_podman) {[$"--requires=($pinp_container)"]})
          --
          $"codeberg.org/potatochronicler/dotfiles/containers/($variant):latest"
      )
  }
}
