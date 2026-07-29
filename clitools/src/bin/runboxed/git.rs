use std::{
    ffi::OsString,
    os::unix::ffi::OsStringExt,
    path::{Path, PathBuf},
    process::{Command, Stdio},
};

pub fn find_dir(path: Option<&Path>) -> std::io::Result<Option<PathBuf>> {
    debug_assert!(match path {
        Some(path) => path.is_dir(),
        None => true,
    });

    let mut git_cmd = Command::new("git");

    if let Some(path) = path {
        git_cmd.arg("-C").arg(path);
    }

    git_cmd.args(["rev-parse", "--show-cdup"]);

    let git_output = git_cmd.stderr(Stdio::null()).output()?;

    if git_output.status.success() {
        let mut output = git_output.stdout;

        if output.ends_with(b"\n") {
            output.pop();
        }

        Ok(Some(PathBuf::from(OsString::from_vec(output))))
    } else {
        Ok(None)
    }
}
