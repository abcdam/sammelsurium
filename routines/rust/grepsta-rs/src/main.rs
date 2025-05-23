use clap::Parser;
use grepsta_rs::CommandRunner;

use grepsta_rs::{Cli, CommandKind};
use grepsta_rs::{get, list};
fn main() -> Result<(), Box<dyn std::error::Error>> {
    match Cli::parse().command {
        CommandKind::Get(pub_config) => get::Runner::dispatch(pub_config)?,
        CommandKind::List(pub_config) => list::Runner::dispatch(pub_config)?,
    }
    Ok(())
}
