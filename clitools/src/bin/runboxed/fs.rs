use std::{
    borrow::Cow,
    ffi::OsStr,
    os::unix::ffi::OsStrExt,
    path::{Path, PathBuf},
};

use log::trace;
use nix::{
    fcntl::readlink,
    unistd::{AccessFlags, access},
};

use crate::git;

/// Returns the git directory, or current working directory if it cannot be found
/// Can return both a relative and absolute path!
pub fn extract_project_directory(filename: Option<&OsStr>) -> Result<PathBuf, std::io::Error> {
    match filename {
        Some(filename) => {
            let path = Path::new(filename);

            if path.is_dir() || path == "/" {
                Ok(git::find_dir(Some(path))?.unwrap_or(path.to_path_buf()))
            } else {
                let parent = path.parent();
                let git_dir = match parent {
                    Some(parent) if parent != "" => git::find_dir(Some(parent)).map(|r| {
                        r.map(|d| {
                            // This result is relative to `parent`,
                            // so we have to absolute this here, otherwise the information is gone
                            parent.join(d)
                        })
                    }),
                    _ => git::find_dir(None),
                }?;

                git_dir.map_or_else(|| std::env::current_dir(), Ok)
            }
        }
        None => git::find_dir(None)?.map_or_else(|| std::env::current_dir(), Ok),
    }
}

pub fn is_protected_directory(path: &Path) -> bool {
    path == "/" || path == "/home" || {
        if let Ok(path) = std::path::absolute(path) {
            let mut c = path.components();
            match (c.next(), c.next(), c.next(), c.next()) {
                (
                    Some(std::path::Component::RootDir),
                    Some(std::path::Component::Normal(first_section)),
                    Some(_),
                    None,
                ) => first_section == OsStr::from_bytes("home".as_bytes()),
                _ => false,
            }
        } else {
            false
        }
    }
}

/// Searches PATH for the passed-in executable, skipping those that are aliased to runboxed
pub fn find_executable<'e, 'p>(exec: &'e Path, path_var: &'p OsStr) -> Option<Cow<'e, Path>> {
    fn is_runboxed(path: &OsStr) -> bool {
        let path = path.as_bytes();
        path.ends_with(b"/runboxed") || path == b"runboxed"
    }

    if let Ok(link) = readlink(exec) {
        if !is_runboxed(&link) {
            return Some(Cow::Borrowed(exec));
        }
    }

    // Don't use std::fs::split_paths, creates unnecessary allocations
    let path = path_var.as_bytes().split(|&c| c == b':');

    path.map(|d| Path::new(OsStr::from_bytes(d)).join(exec))
        .find(|p| {
            trace!("testing path {p:?}");

            access(p, AccessFlags::X_OK).is_ok() && {
                let link = readlink(p);
                if let Ok(link) = link {
                    !is_runboxed(&link)
                } else {
                    true
                }
            }
        })
        .map(Cow::Owned)
}
