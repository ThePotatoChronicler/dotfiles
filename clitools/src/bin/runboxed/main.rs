#![feature(
    error_generic_member_access,
    normalize_lexically,
    never_type,
    vec_try_remove
)]

mod args;
mod bwrap;
mod config;
mod executable;
mod fs;
mod git;

use std::{
    backtrace::Backtrace,
    borrow::Cow,
    env::var_os,
    ffi::{OsStr, OsString},
    fs::DirBuilder,
    os::unix::{ffi::OsStrExt, fs::DirBuilderExt, process::CommandExt},
    path::Path,
};

use anyhow::anyhow;
use clap::Parser;
use log::{debug, trace};
use thiserror::Error;

use args::Args;

use crate::{
    args::CmdlineArgs, bwrap::environment::Environment, executable::SpecialExecutable,
    fs::find_executable,
};

use const_format::{Case, concatcp, map_ascii_case};

#[derive(Debug, Error)]
#[error("failed to start bwrap")]
struct BwrapStartError {
    #[from]
    source: std::io::Error,
}

#[derive(Debug, Error)]
#[error("could not obtain executable to run")]
struct NoExecutableError {
    backtrace: Backtrace,
}

fn is_path_runboxed(path: &Path) -> bool {
    path.file_name()
        .is_some_and(|p| p.to_string_lossy().as_ref() == "runboxed")
}

fn is_var_enabled(var: impl AsRef<OsStr>) -> bool {
    matches!(var.as_ref().as_bytes(), b"1" | b"true" | b"TRUE")
}

fn main() -> anyhow::Result<!> {
    env_logger::init();

    let mut raw_cmd_args: Vec<_> = std::env::args_os().collect();

    trace!("raw_cmd_args: {raw_cmd_args:?}");

    let arg0 = raw_cmd_args.get(0);

    debug!("arg0: {arg0:?}");

    let behave_as = arg0.and_then(|a| {
        if is_path_runboxed(Path::new(&a)) {
            None
        } else {
            Some(a)
        }
    });

    debug!("behave as: {behave_as:?}");

    let edit_file_var = || var_os("RUNBOXED_EDIT_FILE");

    fn get_first_file_arg(
        special_executable: Option<SpecialExecutable>,
        args: &[OsString],
    ) -> Option<OsString> {
        if config::editor(special_executable) {
            args.iter()
                .find(|&a| !a.as_bytes().starts_with(b"-"))
                .cloned()
        } else {
            None
        }
    }

    let can_bind_all_var = || var_os("RUNBOXED_CAN_BIND_ALL").is_some_and(is_var_enabled);

    let path_var = std::env::var_os("PATH");

    let args = if let Some(_) = behave_as {
        let behave_as = raw_cmd_args.remove(0);

        let path_var =
            path_var.ok_or_else(|| anyhow!("cannot behave as another program without PATH"))?;

        let special_executable = SpecialExecutable::from_path(Path::new(&behave_as));

        let edit_file =
            get_first_file_arg(special_executable, &raw_cmd_args).or_else(edit_file_var);

        make_args!(
            Args {
                special_executable,
                executable_path: std::path::absolute(Path::new(&behave_as))?
                    .file_name()
                    .map(|p| find_executable(Path::new(p), &path_var))
                    .flatten()
                    .map(Cow::into_owned)
                    .map(Into::into)
                    .ok_or_else(|| anyhow!("cannot find executable to run"))?,
                args: raw_cmd_args,
                can_bind_all: can_bind_all_var(),
                edit_file,
            },
            [dbus, gpu, gui, internet, setsid, no_project],
            special_executable = special_executable,
        )
    } else {
        let mut cmd_args = CmdlineArgs::parse_from(raw_cmd_args);

        trace!("cmd_args: {cmd_args:?}");

        let executable = cmd_args.args.try_remove(0).map(Into::into).map_or_else(
            || {
                var_os("SHELL").ok_or_else(|| NoExecutableError {
                    backtrace: Backtrace::capture(),
                })
            },
            Ok,
        )?;

        trace!("executable: {executable:?}");

        let executable: OsString = path_var
            .map(|path| find_executable(Path::new(&executable), &path))
            .flatten()
            .map(Cow::into_owned)
            .map(Into::into)
            .unwrap_or(executable);

        trace!("executable: {executable:?}");

        let special_executable = if !cmd_args.not_special {
            SpecialExecutable::from_path(Path::new(&executable))
        } else {
            None
        };

        let args: Vec<_> = cmd_args.args.into_iter().map(|v| v.into()).collect();

        let edit_file = cmd_args
            .edit_file
            .map(Into::into)
            .or_else(|| get_first_file_arg(special_executable, &args))
            .or_else(edit_file_var);

        make_args!(
            Args {
                special_executable,
                executable_path: executable,
                args,
                can_bind_all: cmd_args.can_bind_all || can_bind_all_var(),
                edit_file,
            },
            [dbus, gpu, gui, internet, setsid, no_project],
            special_executable = special_executable,
            take_from = cmd_args
        )
    };

    debug!("args: {args:?}");

    if let Some(exec) = &args.special_executable {
        match exec {
            SpecialExecutable::Nu => {
                DirBuilder::new()
                    .mode(0o700)
                    .recursive(true)
                    .create("/tmp")?;
            }
            _ => {}
        };
    }

    let mut command = bwrap::command::build(&args, Environment::collect(&args)?)?;

    debug!("bwrap command: {command:?}");

    let exec_error = command.exec();

    Err(BwrapStartError::from(exec_error).into())
}
