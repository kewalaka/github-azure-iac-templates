# Setup Checkov Action

This action provides a reusable way to install Checkov and set up configuration files across different Infrastructure as Code scanning workflows.

## Usage

```yaml
- name: Setup Checkov
  uses: ./.github/actions/setup-checkov
  with:
    working_directory: './iac'
    config_source_path: '${{ github.action_path }}/.checkov.yml'
```

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `working_directory` | Working directory where checkov configuration should be placed | Yes |
| `config_source_path` | Path to the default checkov config to copy if none exists | Yes |

## What it does

1. Installs Checkov using pip
2. Checks if a `.checkov.yml` file exists in the working directory
3. If no config exists, copies the default config from the specified source path
4. If a config already exists, uses the existing one

This action consolidates the common setup logic used by both the `checkov-terraform` and `checkov-bicep` actions.