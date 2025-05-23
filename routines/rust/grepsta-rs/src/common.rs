use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum CommonError {
    /// error when de/serializing JSON.
    #[error("JSON parsing failed: {0}")]
    JsonParse(#[from] serde_json::Error),

    /// error when reading/writing files.
    #[error("I/O fs operation failed: {0}")]
    Io(#[from] std::io::Error),

    #[error("Failed config validation: {0}")]
    Validation(String),
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RepoMetadata {
    pub name: String,
    pub html_url: String,
    pub description: Option<String>,
    pub ssh_url: String,
    pub homepage: Option<String>,
    pub topics: Vec<String>,
}

#[derive(Debug, Deserialize)]
pub struct RepoEntry {
    pub full_name: String,
    #[serde(flatten)]
    pub metadata: RepoMetadata,
}
