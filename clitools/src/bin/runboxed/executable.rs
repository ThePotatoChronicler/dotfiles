use std::path::Path;

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
#[non_exhaustive]
pub enum SpecialExecutable {
    Nu,
    Helix,
}

impl SpecialExecutable {
    pub fn from_path(path: &Path) -> Option<Self> {
        type E = SpecialExecutable;

        path.file_name()
            .map(|p| match p.to_string_lossy().as_ref() {
                "nu" => Some(E::Nu),
                "helix" => Some(E::Helix),
                _ => None,
            })
            .flatten()
    }
}
