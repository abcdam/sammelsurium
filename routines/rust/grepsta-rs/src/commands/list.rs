use crate::{
    CommandRunner,
    common::{CommonError, RepoEntry, RepoMetadata},
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

pub struct RunConfig {
    cache_dir: PathBuf,
}

pub struct Runner;

#[derive(ThisError, Debug)]
pub enum Error {
    #[error(transparent)]
    Common(#[from] CommonError),
}

impl TryFrom<PubConfig> for RunConfig {
    type Error = Error;

    fn try_from(cfg: PubConfig) -> Result<Self, Error> {
        let cache_dir = cfg
            .common
            .cache_dir
            .ok_or(CommonError::Validation(
                "cache dir value not set".into(),
            ))?;
        if !cache_dir.is_dir() {
            return Err(CommonError::Validation(format!(
                "path to cache is not a dir"
            )))?;
        }

        Ok(RunConfig { cache_dir })
    }
}

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
