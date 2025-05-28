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
    type Error: Into<Error>;

    /// The public config type as constructed by Clap
    type PubConfig: init::HasCommonOpts;

    /// The internal config type derived from PubConfig. Ensures valid runtime values
    type RunConfig: TryFrom<Self::PubConfig, Error = Self::Error>
        + FromPubCfg<Self::PubConfig>;

    /// Transforms config and runs command
    fn dispatch(pub_cfg: Self::PubConfig) -> Result<(), Self::Error> {
        Self::run(Self::RunConfig::try_from(pub_cfg)?)
    }
    /// internal run implementation
    fn run(run_conf: Self::RunConfig) -> Result<(), Self::Error>;
}

/// public config -> runtime config converter trait
pub trait FromPubCfg<PubConfig>
where
    PubConfig: init::HasCommonOpts,
    Self: Sized,
{
    type Error;

    /// any custom validation logic resides here
    fn validate_from_pub(pub_cfg: PubConfig) -> Result<Self, Self::Error>;

    /// central place for validation logic that is shared across implementations
    fn validate_from_pub_inner(pub_cfg: PubConfig) -> Result<Self, Self::Error>
    where
        Self::Error: From<common::CommonError>,
    {
        let path = pub_cfg
            .common()
            .cache_dir
            .as_ref()
            .ok_or_else(|| {
                common::CommonError::Validation(
                    "cache_dir value not set".into(),
                )
            })?;
        if !path.is_dir() {
            return Err(common::CommonError::Validation(format!(
                "path '{}' not a directory",
                path.display()
            )))?;
        }
        Self::validate_from_pub(pub_cfg)
    }
}

/// helper that generates the type conversion facade
#[macro_export]
macro_rules! impl_validated_try_from {
    ( $PubConfig:ty, $RunConfig:ty ) => {
        impl std::convert::TryFrom<$PubConfig> for $RunConfig {
            type Error = <$RunConfig as FromPubCfg<$PubConfig>>::Error;
            fn try_from(
                pub_cfg: $PubConfig,
            ) -> std::result::Result<
                $RunConfig,
                <$RunConfig as FromPubCfg<$PubConfig>>::Error,
            > {
                <$RunConfig as FromPubCfg<$PubConfig>>::validate_from_pub_inner(
                    pub_cfg,
                )
            }
        }
    };
}
