#![feature(error_generic_member_access, normalize_lexically)]

mod args;
pub(crate) mod bwrap;
pub(crate) mod fs;
pub(crate) mod git;

use std::{fs::DirBuilder, os::unix::fs::DirBuilderExt};

use clap::Parser;
use log::debug;
use thiserror::Error;

pub use args::Args;

use crate::bwrap::environment::Environment;

#[derive(Debug, Error)]
#[error("failed to start bwrap")]
struct BwrapStartError {
    #[from]
    source: std::io::Error,
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
enum SpecialExecutable {
    Nu,
}

fn main() -> anyhow::Result<()> {
    env_logger::init();

    cmd(Args::parse())
}

pub fn cmd(args: Args) -> anyhow::Result<()> {
    let special_executable = match args.args.get(0).map(|s| s.as_str()) {
        Some("nu") => {
            DirBuilder::new()
                .mode(0o700)
                .recursive(true)
                .create("/tmp")?;

            Some(SpecialExecutable::Nu)
        }
        _ => None,
    };

    let mut command = bwrap::command::build(
        &args,
        special_executable.as_ref(),
        Environment::collect(&args)?,
    )?;

    debug!("bwrap command: {command:?}");

    let mut bwrap_process = command.spawn().map_err(Into::<BwrapStartError>::into)?;

    bwrap_process.wait()?;

    Ok(())
}
