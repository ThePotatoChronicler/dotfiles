use clap::Parser;

#[derive(Parser, Debug)]
pub struct Args {
    #[arg(trailing_var_arg = true, num_args = 0.., default_values_t = vec!["nu".to_string()])]
    pub args: Vec<String>,

    /// Allow binding to overly-permissive folders, like /, /home, or $HOME
    #[arg(long)]
    pub can_bind_all: bool,

    /// Share dbus
    #[arg(long)]
    pub dbus: bool,

    /// Says that the executable is an editor, about to edit this file
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

    /// Creates new process group session (bwrap --new-session)
    #[arg(long)]
    pub setsid: bool,
}
