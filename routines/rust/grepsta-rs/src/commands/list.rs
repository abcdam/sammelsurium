use crate::{
    CommandRunner, FromPubCfg,
    common::{CommonError, RepoEntry, RepoMetadata},
    impl_validated_try_from, init,
};
use fuzzy_matcher::{FuzzyMatcher, skim::SkimMatcherV2};

use std::{ffi::OsStr, fs, path::PathBuf};
use thiserror::Error as ThisError;

use clap::Args;
#[derive(Args, Debug)]
pub struct PubConfig {
    #[clap(flatten)]
    pub common: crate::init::CommonOpts,
}

impl init::HasCommonOpts for PubConfig {
    fn common(&self) -> &init::CommonOpts {
        &self.common
    }
}

pub struct RunConfig {
    cache_dir: PathBuf,
}

pub struct Runner;

#[derive(ThisError, Debug)]
pub enum Error {
    #[error(transparent)]
    Common(#[from] CommonError),
}

impl FromPubCfg<PubConfig> for RunConfig {
    type Error = Error;

    fn validate_from_pub(cfg: PubConfig) -> Result<Self, Error> {
        Ok(RunConfig {
            cache_dir: cfg.common.cache_dir.unwrap(),
        })
    }
}

impl_validated_try_from!(PubConfig, RunConfig);

impl CommandRunner for Runner {
    type PubConfig = PubConfig;
    type RunConfig = RunConfig;
    type Error = Error;

    fn run(cfg: RunConfig) -> Result<(), Error> {
        let content_files: Vec<PathBuf> = fs::read_dir(cfg.cache_dir)
            .map_err(CommonError::from)?
            .filter_map(Result::ok) // …so this yields `&DirEntry`
            .map(|entry| entry.path())
            .filter(|p| {
                p.is_file()
                    && p.extension().and_then(OsStr::to_str) == Some("json")
            })
            .collect();
        println!("list: {:#?}", content_files);
        Ok(())
    }
}
