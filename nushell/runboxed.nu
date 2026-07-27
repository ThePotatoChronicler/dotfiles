use ./common.nu *

def extract_project_directory [filename: string]: nothing -> oneof<string, nothing> {
  if (defined_external git) {
    let dir = $filename | path dirname
  
    let git_relative = ^git -C $dir rev-parse --show-cdup | complete

    if $git_relative.exit_code == 0 {
      let git_relative_to_dir = $git_relative.stdout | str replace --regex '\n$' ''
      let git_relative = [ $dir $git_relative_to_dir ] | path join
    
      return ($git_relative | path expand -n)
    }
  }

  if ($filename | path type) == dir {
    return $filename
  }
}

def is_protected_dir [filename: string]: nothing -> bool {
  [$env.HOME / /home] | any {|e| $e == $filename}
}

def clipboard_opts []: nothing -> oneof<list<any>, nothing> {
  if (defined_external wl-copy) and ([ XDG_RUNTIME_DIR WAYLAND_DISPLAY ] | all {|k| $k in $env}) {
    [
      --bind-try ($env.XDG_RUNTIME_DIR)/($env.WAYLAND_DISPLAY) ($env.XDG_RUNTIME_DIR)/($env.WAYLAND_DISPLAY)
    ]
  }
}

def dbus_opts []: nothing -> oneof<list<any>, nothing> {
  let dbus_address = $env.DBUS_SESSION_BUS_ADDRESS?

  if ($dbus_address == null) {
    return
  }

  let dbus_address = $dbus_address | parse "unix:path={path}" | get 0?.path?

  if ($dbus_address == null) {
    return
  }

  [
    --bind $dbus_address $dbus_address
  ]
}

def symlink_opts [filename: oneof<string, nothing>, can_bind_all: bool]: nothing -> oneof<list<any>, nothing> {
  if $filename != null and ($filename | path type) == symlink {
    # Using path expand here will expand too much,
    # we only need first layer, so we use readlink
    let dir = readlink --  $filename | path dirname

    if not $can_bind_all and (is_protected_dir $dir) {
      error make "Binding to $HOME, /home, or / allows the editor to access all your files. To proceed regardless, use --can-bind-all"
    }

    print $"Binding symlink target dir: '($dir)'"
    
    [--bind $dir $dir]
  }
}

def gpu_opts []: nothing -> oneof<list<any>, nothing> {
  [
    --ro-bind-try /sys/bus/pci /sys/bus/pci
    --ro-bind-try /sys/devices/system/memory/block_size_bytes /sys/devices/system/memory/block_size_bytes
    --ro-bind-try /sys/module/nvidia /sys/module/nvidia
    --dev-bind-try /dev/dri /dev/dri
    --dev-bind-try /dev/nvidiactl /dev/nvidiactl
    --dev-bind-try /dev/nvidia0 /dev/nvidia0
    ...(
      %ls /dev/dri
      | where type == "char device"
      | get name
      | each -f {|e|
        let nums = ^stat -c '%Hr %Lr' $e | parse '{major} {minor}' | get 0
        let sys_device = $"/sys/dev/char/($nums.major):($nums.minor)/device"

        [
          --ro-bind-try $sys_device $sys_device
        ]
      }
    )
  ]
}

# FIXME: If files inside the directory, other than the file specified as filename, are symlinks, they won't be resolved
export def main [
  --can-bind-all
  --edit-file: string   # Says that the executable is an editor, about to edit this file
  --internet (-i)
  --dbus
  --gpu
  --gui
  --setsid
  --args: list<string> 
  executable: string = "nu"
]: nothing -> any {
  const config_dirs = [ helix fish nushell ]

  let filename = $edit_file

  let directory: string = (
    ( extract_project_directory ($filename | default { pwd }) )
    | default { $filename | path dirname }
  )

  let source = $directory | path expand
  let target = $directory | path expand -n

  # print $"Directory: '($directory)', Source: '($source)' Target: '($target)'"

  if not $can_bind_all and (is_protected_dir $source) {
    error make "Binding to $HOME, /home, or / allows the editor to access all your files. To proceed regardless, use --can-bind-all"
  }

  let rustup_dir = $env.RUSTUP_HOME? | default { ($env.HOME)/.rustup }

  let rustup_path: oneof<string, nothing> = which rustup | get 0?.path

  const container_bin = "/.container_bin"

  let cachedir = [ $env.HOME .cache/potato_runboxed ] | path join

  let cargo_cache_dir = ($cachedir)/cargo
  let pnpm_cache_dir = ($cachedir)/pnpm
  let helix_cache_dir = ($cachedir)/helix

  mkdir $cargo_cache_dir $pnpm_cache_dir $helix_cache_dir

  (
    ^bwrap
      ...(
        if not $internet {
          [--unshare-net]
        }
      )
      --unshare-ipc
      --unshare-pid
      --unshare-cgroup-try
      --proc /proc
      --dev /dev
      --ro-bind-try /usr /usr
      --ro-bind-try /lib /lib
      --ro-bind-try /bin /bin
      --ro-bind-try /sbin /sbin
      --ro-bind-try /lib64 /lib64
      --ro-bind-try /etc /etc
      ...(if $setsid {[--new-session]})

      --setenv _POTATO_RUNBOXED 1

      --dir /tmp
      --tmpfs /.tmp
      --setenv TMPDIR /.tmp
      --setenv TMP /.tmp

      --bind $cargo_cache_dir ($env.HOME)/.cargo
      --bind $helix_cache_dir ($env.HOME)/.cache/helix
      --bind $pnpm_cache_dir ($env.HOME)/.local/share/pnpm/store

      # `pnpm` sees the store as being on a different filesystem, but in reality, it's not
      # (atleast on my system, it's not, if it's on yours, change this,
      # or maybe I'll make it customizable when it becomes an issue for me)
      # so this way, we force it to believe!
      --setenv PNPM_HOME ($env.HOME)/.local/share/pnpm

      # Configs
      ...(
        $config_dirs | each -f {|$d| [
          --ro-bind-try ($env.HOME)/.config/($d) ($env.HOME)/.config/($d)
        ]}
      )

      ...(
        if $executable == "nu" {
          ^mkdir -p --mode=0700 /tmp/editor-tmp
          touch /tmp/editor-tmp/nushell_history.txt
          [--bind /tmp/editor-tmp/nushell_history.txt ($env.HOME)/.config/nushell/history.txt]
        }
      )

      # Adding a writable directory to path, so we can override commands
      --size (1MiB | into int | into string) --tmpfs $container_bin

      --setenv PATH ($env.PATH | prepend /.container_bin | str join ":")

      # Rustup
      --ro-bind-try $rustup_dir $rustup_dir
      ...(
        # Work-around for systems which don't have a rust-analyzer symlink proxy to rustup
        # For example, Arch doesn't have one
        if ($rustup_path != null) and not (defined_external rust-analyzer) {
          [
            --symlink $rustup_path ($container_bin | path join rust-analyzer)
          ]
        }
      )

      # Clipboard functionality
      ...(clipboard_opts)

      ...(if $dbus {
        dbus_opts
      })

      ...(if $gpu {
          gpu_opts
      })

      ...(
        if $gui {
          [
            --bind-try ($env.HOME)/.cache/fontconfig ($env.HOME)/.cache/fontconfig
            --bind-try ($env.HOME)/.cache/glycin ($env.HOME)/.cache/glycin
            --ro-bind-try ($env.HOME)/.config/vulkan ($env.HOME)/.config/vulkan
            --ro-bind-try ($env.HOME)/.config/dconf ($env.HOME)/.config/dconf
            --ro-bind-try ($env.HOME)/.config/kdedefaults ($env.HOME)/.config/kdedefaults
            --ro-bind-try ($env.HOME)/.config/gtk-3.0 ($env.HOME)/.config/gtk-3.0
            --ro-bind-try ($env.HOME)/.local/share/vulkan ($env.HOME)/.local/share/vulkan
            --ro-bind-try ($env.HOME)/.local/share/glib-2.0 ($env.HOME)/.local/share/glib-2.0
            --ro-bind-try ($env.HOME)/.local/share/themes ($env.HOME)/.local/share/themes
            --ro-bind-try ($env.HOME)/.local/share/gvfs-metadata ($env.HOME)/.local/share/gvfs-metadata
            --ro-bind-try ($env.HOME)/.fontconfig ($env.HOME)/.fontconfig
            --ro-bind-try ($env.HOME)/.fonts ($env.HOME)/.fonts
            --ro-bind-try ($env.HOME)/.local/share/icons ($env.HOME)/.local/share/icons
            --ro-bind-try ($env.HOME)/.icons ($env.HOME)/.icons
            --ro-bind-try ($env.HOME)/.cursors ($env.HOME)/.cursors
            --ro-bind-try ($env.HOME)/.themes ($env.HOME)/.themes
            --ro-bind-try /var/cache/fontconfig /var/cache/fontconfig
            --bind-try ($env.XDG_RUNTIME_DIR)/at-spi ($env.XDG_RUNTIME_DIR)/at-spi
          ]
        }
      )

      # Resolving symlinks, if we're editing a symlink file
      ...(symlink_opts $filename $can_bind_all)

      --bind $source $target
      --
      $executable
      ...$args
  )
}
