use std::ffi::OsString;

use clap::Parser;

use crate::executable::SpecialExecutable;

#[derive(Parser, Debug, Clone)]
/// Run a program in a limited namespace,
/// only having access to a limited amount of the filesystem
/// and restrictive permissions
pub(crate) struct CmdlineArgs {
    /// Program to run (defaults to $SHELL)
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

    /// Avoids binding a project
    #[arg(long)]
    pub no_project: bool,

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

    /// Avoids binding a project
    pub no_project: bool,

    /// Creates new process group session (bwrap --new-session)
    pub setsid: bool,

    pub special_executable: Option<SpecialExecutable>,
}

#[macro_export]
macro_rules! __args__simple_opt_var_expr {
    ($name: ident) => {
        var_os(concatcp!(
            "RUNBOXED_",
            map_ascii_case!(Case::Upper, stringify!($name))
        ))
        .is_some_and(is_var_enabled)
    };
}

#[macro_export]
macro_rules! __args__simple_opt_impl2 {
    ($name:ident, $special_executable:ident) => {
        $crate::config::$name($special_executable) || $crate::__args__simple_opt_var_expr!($name)
    };
}

#[macro_export]
macro_rules! __args__simple_opt_impl3 {
    ($name:ident, $special_executable:ident, $from:ident) => {
        config::$name($special_executable)
            || $from.$name
            || $crate::__args__simple_opt_var_expr!($name)
    };
}

#[macro_export]
macro_rules! make_args {
    (
        Args { $($manual_fields:tt)* },
        [$($simple_opts:ident),*],
        special_executable = $special_executable:ident $(,)?
    ) => {
        Args {
            $(
                $simple_opts: $crate::__args__simple_opt_impl2!($simple_opts, $special_executable),
            )*
            $($manual_fields)*
        }
    };

    (
        Args { $($manual_fields:tt)* },
        [$($simple_opts:ident),*],
        special_executable = $special_executable:ident,
        take_from = $take_from:ident $(,)?
    ) => {
        Args {
            $(
                $simple_opts: $crate::__args__simple_opt_impl3!($simple_opts, $special_executable, $take_from),
            )*
            $($manual_fields)*
        }
    };
}
