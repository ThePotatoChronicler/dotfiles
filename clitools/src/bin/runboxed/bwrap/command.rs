use std::{
    backtrace::Backtrace,
    ffi::{OsStr, OsString},
    os::unix::{
        ffi::{OsStrExt, OsStringExt},
        fs::{FileTypeExt, MetadataExt},
    },
    path::{Path, PathBuf},
    process::Command,
};

use bytesize::mib;
use const_format::concatcp;
use log::debug;
use thiserror::Error;

use crate::{
    Args, SpecialExecutable,
    bwrap::environment::{DefaultDeferredEnvironment, DeferredEnvironment, Environment},
    fs::{extract_project_directory, is_protected_directory},
};

#[derive(Debug, Error)]
#[error(
    "Binding to $HOME, /home, or / allows the editor to access all your files. To proceed regardless, use --can-bind-all"
)]
struct ProtectedPathError {
    backtrace: Backtrace,
}

pub fn build(
    args: &Args,
    special_executable: Option<&SpecialExecutable>,
    environment: Environment,
) -> anyhow::Result<Command> {
    build_with_env(
        args,
        special_executable,
        environment,
        DefaultDeferredEnvironment,
    )
}

pub fn build_with_env<DE: DeferredEnvironment>(
    args: &Args,
    special_executable: Option<&SpecialExecutable>,
    environment: Environment,
    deferred_environment: DE,
) -> anyhow::Result<Command> {
    const CONTAINER_BIN: &str = "/.container_bin";

    let mut cmd = Command::new("bwrap");

    cmd.arg("--unshare-all");

    if args.internet {
        cmd.arg("--share-net");
    }

    if args.setsid {
        cmd.arg("--new-session");
    }

    #[rustfmt::skip]
    cmd.args([
      "--proc", "/proc",
      "--dev", "/dev",
      "--ro-bind-try", "/usr", "/usr",
      "--ro-bind-try", "/lib", "/lib",
      "--ro-bind-try", "/bin", "/bin",
      "--ro-bind-try", "/sbin", "/sbin",
      "--ro-bind-try", "/lib64", "/lib64",
      "--ro-bind-try", "/etc", "/etc",

      "--setenv", "_POTATO_RUNBOXED", "1",

      "--dir", "/tmp",
      "--tmpfs", "/.tmp",
      "--setenv", "TMPDIR", "/.tmp",
      "--setenv", "TMP", "/.tmp",
    ]);

    let home = environment.home.as_ref();

    let cachedir: PathBuf = [home, Path::new(".cache/potato_runboxed")].iter().collect();

    let cargo_cache_dir: PathBuf = [&cachedir, &"cargo".into()].iter().collect();
    let helix_cache_dir: PathBuf = [&cachedir, &"helix".into()].iter().collect();
    let pnpm_cache_dir: PathBuf = [&cachedir, &"pnpm".into()].iter().collect();

    deferred_environment.create_directory(&cargo_cache_dir)?;
    deferred_environment.create_directory(&helix_cache_dir)?;
    deferred_environment.create_directory(&pnpm_cache_dir)?;

    let cargo_dir: PathBuf = [home, Path::new(".cargo")].iter().collect();
    let helix_dir: PathBuf = [home, Path::new(".cache/helix")].iter().collect();
    let pnpm_dir: PathBuf = [home, Path::new(".local/share/pnpm/store")]
        .iter()
        .collect();

    cmd.arg("--bind")
        .args([cargo_cache_dir, cargo_dir])
        .arg("--bind")
        .args([helix_cache_dir, helix_dir])
        .arg("--bind")
        .args([pnpm_cache_dir, pnpm_dir]);

    // `pnpm` sees the store as being on a different filesystem, but in reality, it's not
    // (atleast on my system, it's not, if it's on yours, change this,
    // or maybe I'll make it customizable when it becomes an issue for me)
    // so this way, we force it to believe!
    cmd.args(["--setenv", "PNPM_HOME"]).arg(
        [home, Path::new("/.local/share/pnpm")]
            .iter()
            .collect::<PathBuf>(),
    );

    for config_dir in ["helix", "fish", "nushell"] {
        let path: PathBuf = [home, Path::new(".config"), Path::new(config_dir)]
            .iter()
            .collect();

        cmd.arg("--ro-bind-try").args([&path, &path]);
    }

    if let Some(SpecialExecutable::Nu) = special_executable {
        deferred_environment.create_directory(Path::new("/tmp/editor-tmp"))?;
        deferred_environment.create_empty_file(Path::new("/tmp/editor-tmp/nushell_history.txt"))?;

        cmd.arg("--bind")
            .arg("/tmp/editor-tmp/nushell_history.txt")
            .arg(
                [home, Path::new(".config/nushell/history.txt")]
                    .iter()
                    .collect::<PathBuf>(),
            );
    }

    cmd.arg("--size")
        .arg(mib(1u64).to_string())
        .arg("--tmpfs")
        .arg(CONTAINER_BIN);

    let box_path = {
        let mut s = environment.path.into_vec();
        s.splice(
            0..0,
            concatcp!(CONTAINER_BIN, ":").as_bytes().iter().copied(),
        );
        OsString::from_vec(s)
    };

    cmd.args(["--setenv", "PATH"]).arg(box_path);

    let rustup_dir = environment
        .rustup_home
        .map(|s| s.into())
        .unwrap_or_else(|| {
            let mut s: PathBuf = home.into();
            s.push(".rustup");
            s.into_os_string()
        });

    cmd.arg("--ro-bind-try").args([&rustup_dir, &rustup_dir]);

    if let Some(rustup_path) = environment.rustup_path {
        if deferred_environment.has_rust_analyzer() {
            cmd.arg("--symlink")
                .arg(rustup_path)
                .arg(concatcp!(CONTAINER_BIN, "/rust-analyzer"));
        }
    }

    if environment.has_wl_copy {
        if let (Some(xdg_runtime_dir), Some(wayland_display)) =
            (&environment.xdg_runtime_dir, &environment.wayland_display)
        {
            let path: PathBuf = [xdg_runtime_dir, wayland_display].iter().collect();

            cmd.arg("--bind-try").args([&path, &path]);
        }
    }

    if args.dbus {
        const DBUS_ADDRESS_PREFIX: &'static str = "unix:path=";

        if let Some(dbus_addr) = environment.dbus_session_bus_address {
            let addr = dbus_addr.into_vec();
            if addr.starts_with(DBUS_ADDRESS_PREFIX.as_bytes()) {
                let addr = OsStr::from_bytes(&addr[DBUS_ADDRESS_PREFIX.len()..]);
                cmd.arg("--bind").args([addr, addr]);
            }
        }
    }

    if args.gpu {
        #[rustfmt::skip]
        cmd.args([
            "--ro-bind-try", "/sys/bus/pci", "/sys/bus/pci",
            "--ro-bind-try", "/sys/devices/system/memory/block_size_bytes", "/sys/devices/system/memory/block_size_bytes",
            "--ro-bind-try", "/sys/module/nvidia", "/sys/module/nvidia",
            "--dev-bind-try", "/dev/dri", "/dev/dri",
            "--dev-bind-try", "/dev/nvidiactl", "/dev/nvidiactl",
            "--dev-bind-try", "/dev/nvidia0", "/dev/nvidia0",
        ]);

        // TODO: Make external to this function, to make this a "pure" function
        if let Ok(dir) = std::fs::read_dir("/dev/dri") {
            let devices = dir
                .filter_map(|f| f.ok())
                .filter(|f| f.file_type().is_ok_and(|f| f.is_char_device()))
                .map(|f| -> Result<_, std::io::Error> {
                    let metadata = f.metadata()?;
                    let rdev = metadata.rdev();
                    let major = nix::sys::stat::major(rdev);
                    let minor = nix::sys::stat::minor(rdev);

                    Ok((major, minor))
                });

            for device in devices {
                let (major, minor) = device?;
                let path = format!("/sys/dev/char/{major}:{minor}/device");
                cmd.arg("--ro-bind-try").args([&path, &path]);
            }
        }
    }

    if args.gui {
        for dir in [
            ".cache/fontconfig",
            ".cache/glycin",
            ".config/vulkan",
            ".config/dconf",
            ".config/kdedefaults",
            ".config/gtk-3.0",
            ".local/share/vulkan",
            ".local/share/glib-2.0",
            ".local/share/themes",
            ".local/share/gvfs-metadata",
            ".fontconfig",
            ".fonts",
            ".local/share/icons",
            ".icons",
            ".cursors",
            ".themes",
        ] {
            let path: PathBuf = [home, Path::new(dir)].iter().collect();
            cmd.arg("--ro-bind-try").args([&path, &path]);
        }

        cmd.args([
            "--ro-bind-try",
            "/var/cache/fontconfig",
            "/var/cache/fontconfig",
        ]);

        if let Some(ref xdg) = environment.xdg_runtime_dir {
            let path: PathBuf = [xdg, OsStr::new("at-spi")].iter().collect();
            cmd.arg("--bind-try").args([&path, &path]);
        }
    }

    if let Some(filename) = &args.edit_file {
        if let Ok(target) = std::fs::read_link(filename) {
            if !args.can_bind_all && is_protected_directory(&target) {
                return Err(anyhow::anyhow!(ProtectedPathError {
                    backtrace: Backtrace::capture(),
                }));
            }

            cmd.arg("--bind").args([&target, &target]);
        }
    }

    let project_directory = extract_project_directory(args.edit_file.as_deref())?;

    debug!("Project directory: {project_directory:?}");

    let project_directory = if project_directory.is_absolute() {
        project_directory
    } else {
        // We must use PWD to preserve the symlinks in the current directory
        // PWD might not exist or be wrong (not handled here),
        // at which point we go back to classic `current_dir()`
        let mut cwd_relative =
            std::env::var_os("PWD").map_or_else(|| std::env::current_dir(), |s| Ok(s.into()))?;

        cwd_relative.push(project_directory);
        cwd_relative.normalize_lexically().unwrap_or(cwd_relative)
    };

    debug!("Canonical project directory: {project_directory:?}");

    if is_protected_directory(&project_directory) {
        return Err(anyhow::anyhow!(ProtectedPathError {
            backtrace: Backtrace::capture(),
        }));
    }

    cmd.arg("--bind")
        .arg(
            project_directory
                .canonicalize()
                .as_deref()
                .unwrap_or(&project_directory),
        )
        .arg(&project_directory);

    cmd.arg("--");
    cmd.args(&args.args);

    Ok(cmd)
}
