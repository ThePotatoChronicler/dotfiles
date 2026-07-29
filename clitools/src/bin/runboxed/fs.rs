use std::{
    ffi::OsStr,
    os::unix::ffi::OsStrExt,
    path::{Path, PathBuf},
};

use crate::git;

pub fn extract_project_directory(filename: Option<&str>) -> Result<PathBuf, std::io::Error> {
    match filename {
        Some(filename) => {
            let path = Path::new(filename);

            if path.is_dir() || path == "/" {
                Ok(git::find_dir(Some(path))?.unwrap_or(path.to_path_buf()))
            } else {
                let parent = path.parent();
                let git_dir = match parent {
                    Some(p) if p != "" => git::find_dir(Some(p)),
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
