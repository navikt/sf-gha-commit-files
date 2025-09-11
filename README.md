# Commit files

This action allows you to commit files to a GitHub repository.

## Usage

<!-- Start usage -->
```yaml
- uses: navikt/sf-gha-commit-files@<tag/sha>
    with:
        # List of filenames with path to the files to commit, separated by a comma
        # Required: true
        files: ''
        
        # Commit message
        # Default: "Commit from bot"
        # Required: true
        commitMessage: ''
        
        # GitHub token
        # Required: true'
        token: ''
```
<!-- end usage -->

## Henvendelser

Spørsmål knyttet til koden eller prosjektet kan stilles som issues her på GitHub.

## For NAV-ansatte

Interne henvendelser kan sendes via Slack i kanalen #platforce.
