use thiserror::Error as ThisError;

pub mod commands;
pub mod common;
mod init;

pub use commands::{get, list};
pub use init::{Cli, CommandKind};
#[derive(ThisError, Debug)]
pub enum Error {
    #[error("Failed to run 'get' command: {0}")]
    Get(#[from] commands::get::Error),

    #[error("Failed to run 'list' command: {0}")]
    List(#[from] commands::list::Error),
}

pub trait CommandRunner: Sized {
    type Error;

    /// The config as constructed by Clap
    type PubConfig;

    /// The runtime-validated config used during cmd execution
    type RunConfig: TryFrom<Self::PubConfig, Error = Self::Error>;

    /// Transforms config and runs command
    fn dispatch(pub_cfg: Self::PubConfig) -> Result<(), Self::Error> {
        Self::run(Self::RunConfig::try_from(pub_cfg)?)
    }
    /// internal run implementation
    fn run(run_conf: Self::RunConfig) -> Result<(), Self::Error>;
}
