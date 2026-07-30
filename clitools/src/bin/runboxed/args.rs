use std::ffi::OsString;

use clap::Parser;

use crate::executable::SpecialExecutable;

#[derive(Parser, Debug, Clone)]
pub(crate) struct CmdlineArgs {
    /// Arguments for the program
    #[arg(trailing_var_arg = true, num_args = 0..)]
    pub args: Vec<String>,

    /// Allow binding to overly-permissive folders, like /, /home, or $HOME
    #[arg(long)]
    pub can_bind_all: bool,

    /// Share dbus
    #[arg(long)]
    pub dbus: bool,

    /// Says that the executable is about to edit this file
    #[arg(long)]
    pub edit_file: Option<String>,

    /// Share gpu
    #[arg(long)]
    pub gpu: bool,

    /// Shares things possibly necessary to run GUIs
    #[arg(long)]
    pub gui: bool,

    /// Enable internet
    #[arg(long, short)]
    pub internet: bool,

    /// Prevents special handling of certain programs
    #[arg(long)]
    pub not_special: bool,

    /// Creates new process group session (bwrap --new-session)
    #[arg(long)]
    pub setsid: bool,
}

#[derive(Clone, Debug)]
pub(crate) struct Args {
    /// Arguments for the program
    pub args: Vec<OsString>,

    /// Allow binding to overly-permissive folders, like /, /home, or $HOME
    pub can_bind_all: bool,

    /// Share dbus
    pub dbus: bool,

    /// Says that the executable is an editor, about to edit this file
    pub edit_file: Option<OsString>,

    pub executable_path: OsString,

    /// Share gpu
    pub gpu: bool,

    /// Shares things possibly necessary to run GUIs
    pub gui: bool,

    /// Enable internet
    pub internet: bool,

    /// Creates new process group session (bwrap --new-session)
    pub setsid: bool,

    pub special_executable: Option<SpecialExecutable>,
}
