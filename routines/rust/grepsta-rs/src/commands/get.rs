use crate::{
    CommandRunner,
    common::{CommonError, RepoEntry, RepoMetadata},
    init,
};
use clap::Args;
use futures::{StreamExt, stream::FuturesUnordered};
use regex::Regex;
use reqwest::{Client, Response};
use std::{collections::BTreeMap, path::PathBuf, pin::Pin, sync::Arc};
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

    /// regex crate errors
    #[error("Regex parsing failed: {0}")]
    Regex(#[from] regex::Error),

    #[error("ParseInt error: {0}")]
    Parse(#[from] std::num::ParseIntError),
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

struct RepoFetcher {
    client: Arc<Client>,
    base_url: String,
}
type RepoBatchFuture = Pin<Box<dyn Future<Output = Result<Vec<RepoEntry>>>>>;
impl RepoFetcher {
    fn new(client: Client, username: &str, results_per_page: u8) -> Self {
        RepoFetcher {
            client: Arc::new(client),
            base_url: format!(
                "https://api.github.com/users/{username}/starred?per_page={results_per_page}",
            ),
        }
    }

    fn extract_last_page(response: &Response) -> Result<usize> {
        let link_header = response
            .headers()
            .get(reqwest::header::LINK)
            .and_then(|h| h.to_str().ok())
            .ok_or_else(|| {
                CommonError::Unexpected("Missing LINK entry in response header")
            })?;

        let num_fetchable_pages: usize =
            Regex::new(r#"page=(?<last_idx>\d+)>;\s*rel="last""#)?
                .captures(link_header)
                .ok_or(CommonError::Unexpected(
                    "Failed to extract last page number",
                ))?
                .name("last_idx")
                .ok_or(CommonError::Unexpected(
                    "Empty 'last_idx' capture group",
                ))?
                .as_str()
                .parse()?;
        Ok(num_fetchable_pages)
    }

    async fn fetch_url(&self, page_num: usize) -> Result<Response> {
        let response = self
            .client
            .get(format!("{}&page={}", self.base_url, page_num))
            .send()
            .await?
            .error_for_status()?;
        Ok(response)
    }

    async fn get_async_iter(
        self,
    ) -> Result<impl Iterator<Item = RepoBatchFuture>> {
        let initial_response = self.fetch_url(1).await?;
        let last_page_idx = Self::extract_last_page(&initial_response)?;

        let initial_response_body = initial_response.text().await?;
        let initial_entries: Vec<RepoEntry> =
            serde_json::from_str(&initial_response_body)
                .map_err(CommonError::from)?;

        let fetcher_arc = Arc::new(self);
        let fetch_handler = move |page_num| -> RepoBatchFuture {
            let fetcher = Arc::clone(&fetcher_arc);
            Box::pin(async move {
                let response = fetcher.fetch_url(page_num).await?;
                let text_body = response.text().await?;
                Ok(serde_json::from_str(&text_body)
                    .map_err(CommonError::from)?)
            })
        };

        let first_future: RepoBatchFuture =
            Box::pin(async move { Ok(initial_entries) });
        let rest_iter = (2..=last_page_idx).map(fetch_handler);
        Ok(std::iter::once(first_future).chain(rest_iter))
    }
}

fn fetch_starred_repos(
    username: &str,
) -> Result<BTreeMap<String, RepoMetadata>> {
    let client = reqwest::Client::builder()
        .user_agent("grepsta-rs-client")
        .build()?;

    let rt =
        tokio::runtime::Runtime::new().expect("failed to create Tokio runtime");

    rt.block_on(async {
        let mut fcfs_iter: FuturesUnordered<_> =
            RepoFetcher::new(client, username, 25)
                .get_async_iter()
                .await?
                .collect();

        let mut starred_repos = BTreeMap::new();
        while let Some(batch) = fcfs_iter.next().await {
            starred_repos.extend(
                batch?
                    .into_iter()
                    .map(|repo| (repo.full_name, repo.metadata)),
            );
        }
        Ok(starred_repos)
    })
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
        if !cache_dir.is_dir() {
            return Err(CommonError::Validation(format!(
                "path '{}' not a directory",
                cache_dir.display()
            )))?;
        }
        let user_id = cfg.user_id;
        if user_id.is_empty() {
            return Err(CommonError::Validation(
                "username is not valid/empty".into(),
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

        let filename = format!("{}_starred.json", cfg.user_id);
        let out_path = cfg.cache_dir.join(filename);
        let file =
            std::fs::File::create(&out_path).map_err(CommonError::from)?;

        serde_json::to_writer_pretty(file, &starred_repos)
            .map_err(CommonError::from)?;

        println!(
            "Successfully wrote {} starred repos to {}",
            starred_repos.len(),
            out_path.display()
        );
        Ok(())
    }
}
