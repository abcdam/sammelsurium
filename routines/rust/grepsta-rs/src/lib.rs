use reqwest::blocking::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fmt;

#[derive(Debug)]
pub enum RepoError {
    ClientCreation(reqwest::Error),
    HttpRequest(reqwest::Error),
    InvalidStatus(reqwest::StatusCode),
    JsonParse(serde_json::Error),
}

impl fmt::Display for RepoError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            RepoError::ClientCreation(e) => {
                write!(f, "Failed to create reqwest client: {}", e)
            }
            RepoError::HttpRequest(e) => {
                write!(f, "HTTP request failed: {}", e)
            }
            RepoError::InvalidStatus(s) => {
                write!(f, "Received non-success status code: {}", s)
            }
            RepoError::JsonParse(e) => {
                write!(f, "JSON parsing failed: {}", e)
            }
        }
    }
}
impl std::error::Error for RepoError {}

#[derive(Debug, Serialize, Deserialize)]
pub struct RepoData {
    pub name: String,
    pub html_url: String,
    pub description: Option<String>,
    pub ssh_url: String,
    pub homepage: Option<String>,
    pub topics: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct GitHubRepo {
    full_name: String,
    #[serde(flatten)]
    data: RepoData,
}

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
    type Item = Result<Vec<GitHubRepo>, RepoError>;

    fn next(&mut self) -> Option<Self::Item> {
        let Some(next_page) = self.next_page else {
            return None;
        };

        let reply = (|| -> Result<Vec<GitHubRepo>, RepoError> {
            let url = format!("{}&page={}", self.base_url, next_page);

            let response = self
                .client
                .get(&url)
                .send()
                .map_err(RepoError::HttpRequest)?
                .error_for_status()
                .map_err(|e| RepoError::InvalidStatus(e.status().unwrap()))?;

            serde_json::from_reader(response).map_err(RepoError::JsonParse)
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
            Err(e) => {
                self.next_page = None;
                Some(Err(e))
            }
        }
    }
}

pub fn fetch_starred_repos(
    username: &str,
) -> Result<HashMap<String, RepoData>, RepoError> {
    let client = reqwest::blocking::Client::builder()
        .user_agent("grepsta-rs-client")
        .build()
        .map_err(RepoError::ClientCreation)?;

    let mut starred_repos = HashMap::new();

    for repos_batch in RepoIterator::new(client, username, 50) {
        starred_repos.extend(
            repos_batch?
                .into_iter()
                .map(|repo| (repo.full_name, repo.data)),
        );
    }

    Ok(starred_repos)
}
