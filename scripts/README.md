# Maintenance Scripts

This directory contains scripts used for repository maintenance and security auditing.

## Content Scrubbing

- `git_filter_repo.py`: The [git-filter-repo](https://github.com/newren/git-filter-repo) tool used for rewriting git history.
- `scrub_devise.py`: A custom script used to scrub a specific leaked Devise secret key from the repository history.

## Usage

These scripts are kept for historical reference. To run them (NOT RECOMMENDED unless you know what you are doing):

```bash
python3 scripts/scrub_devise.py
```

> [!WARNING]
> Running these scripts effectively rewrites git history and requires a force push.
