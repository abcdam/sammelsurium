use clap::{Parser, Subcommand};
// use figment::{
//     Figment,
//     providers::{Format, Serialized, Yaml},
// };

use std::path::PathBuf;

use crate::commands::{get, list};

/// Simple fetcher of starred repos to skip UI navigation
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
pub struct CommonOpts {
    // #[command(subcommand)] // #[serde(skip_deserializing)]
    /// WIP: merge configs from external sources (e.g. FILE)
    #[arg(short, long, value_name = "FILE")] // #[serde(skip)]
    pub config_file: Option<PathBuf>,

    #[arg(long, value_name = "DIR")]
    pub cache_dir: Option<PathBuf>,
}

pub trait HasCommonOpts {
    fn common(&self) -> &CommonOpts;
}

// impl Default for GlobalConfig {
//     fn default() -> Self {
//         GlobalConfig {
//             command: Commands::default(), // temporary default value
//             config_file: PathBuf::from("config.yaml"),
//             cache_dir: Some(PathBuf::from("repo-data")),
//         }
//     }
// }
// impl Default for Commands {
//     fn default() -> Commands {
//         Commands::List
//     }
// }

#[derive(Subcommand, Debug)]
pub enum CommandKind {
    /// Fetch starred repos from gh
    Get(get::PubConfig),
    /// Browse entries
    List(list::PubConfig),
}

#[derive(Parser, Debug)]
pub struct Cli {
    #[clap(flatten)]
    pub common: CommonOpts,

    #[command(subcommand)]
    pub command: CommandKind,
}

// impl Commands {
//     pub fn run(
//         &self,
//         cfg: GlobalConfig,
//     ) -> Result<(), Box<dyn std::error::Error>> {
//         use commands::get;
//         match self {
//             Commands::Get { .. } => get::Config::new(cfg)?.run()?,
//             _ => return Ok(()), // Commands::List => todo!,
//         };
//         Ok(())
//     }
// }

// impl GlobalConfig {
//     pub fn load() -> Result<Self, Box<dyn std::error::Error>> {
//         let cli_cfg = Self::parse();

//         let merged_cfg: GlobalConfig = Figment::new()
//             .merge(Serialized::defaults(GlobalConfig::default()))
//             .merge(Yaml::file(&cli_cfg.config_file))
//             .merge(Serialized::globals(cli_cfg))
//             .extract()?;
//         Ok(merged_cfg)
//     }
// }
