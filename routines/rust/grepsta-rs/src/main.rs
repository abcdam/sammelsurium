use clap::Parser;
use std::error::Error;

/// Simple fetcher of starred repos to skip UI navigation
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// GitHub username to fetch starred repositories for
    username: String,
}

fn main() -> Result<(), Box<dyn Error>> {
    run(Args::parse())
}

fn run(args: Args) -> Result<(), Box<dyn Error>> {
    let starred_repos = grepsta_rs::fetch_starred_repos(&args.username)?;

    let output_filename = format!("{}_starred.json", args.username);
    let file = std::fs::File::create(&output_filename)?;
    serde_json::to_writer_pretty(file, &starred_repos)?;

    println!(
        "Successfully wrote {} starred repos to {}",
        starred_repos.len(),
        output_filename
    );
    Ok(())
}
