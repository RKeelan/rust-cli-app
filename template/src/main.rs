use clap::Parser;

#[derive(Parser)]
#[command(version, about)]
struct Cli {
    // Add arguments here
}

fn main() -> anyhow::Result<()> {
    let _cli = Cli::parse();
    println!("Hello from {{ project-name }}!");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::CommandFactory;

    #[test]
    fn cli_parses_without_error() {
        Cli::command().debug_assert();
    }
}
