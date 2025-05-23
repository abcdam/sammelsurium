use crate::{
    CommandRunner,
    common::{CommonError, RepoEntry, RepoMetadata},
    init,
};
use clap::Args;
use reqwest::blocking::Client;
use std::{collections::BTreeMap, path::PathBuf};
use thiserror::Error as ThisError;

#[derive(ThisError, Debug)]
pub enum Error {
    #[error(transparent)]
    Common(#[from] CommonError),

    /// For errors related to the reqwest client.
    #[error("Network/HTTP error: {0}")]
    HttpClient(reqwest::Error),

    /// server response related errors
    #[error("Received non‐success status code: {0}")]
    InvalidStatus(reqwest::StatusCode, &'static str),
}
type Result<T> = std::result::Result<T, Error>;
impl From<reqwest::Error> for Error {
    fn from(e: reqwest::Error) -> Self {
        if let Some(response_code) = e.status() {
            Error::InvalidStatus(
                response_code,
                response_code
                    .canonical_reason()
                    .unwrap_or("No reason"),
            )
        } else {
            Error::HttpClient(e)
        }
    }
}

#[derive(Args, Debug)]
pub struct PubConfig {
    #[clap(flatten)]
    pub common: init::CommonOpts,
    pub user_id: String,
}

pub struct RunConfig {
    user_id: String,
    cache_dir: PathBuf,
}

pub struct Runner;

struct RepoIterator {
    client: Client,
    base_url: String,
    next_page: Option<u8>,
}

impl RepoIterator {
    fn new(client: Client, username: &str, results_per_page: u8) -> Self {
        RepoIterator {
            client,
            base_url: format!(
                "https://api.github.com/users/{username}/starred?per_page={results_per_page}",
            ),
            next_page: Some(1),
        }
    }
}

impl Iterator for RepoIterator {
    type Item = Result<Vec<RepoEntry>>;

    fn next(&mut self) -> Option<Self::Item> {
        let Some(next_page) = self.next_page else {
            return None;
        };

        let reply = (|| -> Self::Item {
            let url = format!("{}&page={}", self.base_url, next_page);

            let response = self
                .client
                .get(&url)
                .send()?
                .error_for_status()?;

            Ok(serde_json::from_reader(response).map_err(CommonError::from)?)
        })();

        match reply {
            Ok(repos) if repos.is_empty() => {
                self.next_page = None;
                None
            }
            Ok(repos) => {
                self.next_page = Some(next_page + 1);
                Some(Ok(repos))
            }
            Err(err) => match err {
                Error::InvalidStatus(..) => Some(Err(err)),
                _ => {
                    self.next_page = None;
                    Some(Err(err))
                }
            },
        }
    }
}

fn fetch_starred_repos(
    username: &str,
) -> Result<BTreeMap<String, RepoMetadata>> {
    let client = reqwest::blocking::Client::builder()
        .user_agent("grepsta-rs-client")
        .build()?;

    let mut starred_repos = BTreeMap::new();

    for repos_batch in RepoIterator::new(client, username, 50) {
        starred_repos.extend(
            repos_batch?
                .into_iter()
                .map(|repo| (repo.full_name, repo.metadata)),
        );
    }

    Ok(starred_repos)
}

impl TryFrom<PubConfig> for RunConfig {
    type Error = Error;

    fn try_from(cfg: PubConfig) -> Result<Self> {
        let cache_dir = cfg
            .common
            .cache_dir
            .ok_or(CommonError::Validation(
                "cache dir value not set".into(),
            ))?;
        let user_id = cfg.user_id;
        let false = user_id.is_empty() else {
            return Err(CommonError::Validation(
                "username is not valid".into(),
            ))?;
        };

        Ok(RunConfig { user_id, cache_dir })
    }
}

impl CommandRunner for Runner {
    type PubConfig = PubConfig;
    type RunConfig = RunConfig;
    type Error = Error;

    fn run(cfg: RunConfig) -> Result<()> {
        let starred_repos = fetch_starred_repos(&cfg.user_id)?;

        let output_filename = format!("{}_starred.json", cfg.user_id);
        let file = std::fs::File::create(&output_filename)
            .map_err(CommonError::from)?;

        serde_json::to_writer_pretty(file, &starred_repos)
            .map_err(CommonError::from)?;

        println!(
            "Successfully wrote {} starred repos to {}",
            starred_repos.len(),
            output_filename
        );
        Ok(())
    }
}
