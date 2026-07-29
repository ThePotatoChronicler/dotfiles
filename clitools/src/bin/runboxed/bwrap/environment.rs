use std::{
    ffi::OsString,
    fs::OpenOptions,
    path::{Path, PathBuf},
};

use thiserror::Error;
use which::which;

use crate::Args;

pub struct Environment {
    pub home: PathBuf,
    pub path: OsString,
    pub rustup_home: Option<OsString>,
    pub rustup_path: Option<PathBuf>,
    pub xdg_runtime_dir: Option<OsString>,
    pub wayland_display: Option<OsString>,
    pub has_wl_copy: bool,
    pub dbus_session_bus_address: Option<OsString>,
}

#[derive(Debug, Error)]
pub enum EnvironmentCollectionError {
    #[error("could not find HOME")]
    Home,
    #[error("could not get PATH")]
    Path,
}

impl Environment {
    pub fn collect(args: &Args) -> Result<Environment, EnvironmentCollectionError> {
        Ok(Environment {
            home: std::env::home_dir().ok_or(EnvironmentCollectionError::Home)?,
            path: std::env::var_os("PATH").ok_or(EnvironmentCollectionError::Path)?,
            rustup_home: std::env::var_os("RUSTUP_HOME"),
            rustup_path: which("rustup").ok(),
            xdg_runtime_dir: std::env::var_os("XDG_RUNTIME_DIR"),
            wayland_display: std::env::var_os("WAYLAND_DISPLAY"),
            has_wl_copy: which("wl-copy").is_ok(),
            dbus_session_bus_address: if args.dbus {
                std::env::var_os("DBUS_SESSION_BUS_ADDRESS")
            } else {
                None
            },
        })
    }
}

pub trait DeferredEnvironment {
    type CreateDirectoryError: std::fmt::Debug + std::error::Error + Send + Sync + 'static;
    type CreateEmptyFileError: std::fmt::Debug + std::error::Error + Send + Sync + 'static;

    fn has_rust_analyzer(&self) -> bool {
        which("rust-analyzer").is_ok()
    }

    fn create_directory(&self, path: &Path) -> Result<(), Self::CreateDirectoryError>;

    fn create_empty_file(&self, path: &Path) -> Result<(), Self::CreateEmptyFileError>;
}

pub struct DefaultDeferredEnvironment;

impl DeferredEnvironment for DefaultDeferredEnvironment {
    type CreateDirectoryError = std::io::Error;
    type CreateEmptyFileError = std::io::Error;

    fn create_directory(&self, path: &Path) -> Result<(), Self::CreateDirectoryError> {
        std::fs::create_dir_all(path)
    }

    fn create_empty_file(&self, path: &Path) -> Result<(), Self::CreateEmptyFileError> {
        OpenOptions::new()
            .create(true)
            .write(true)
            .open(path)
            .map(|_| ())
    }
}
