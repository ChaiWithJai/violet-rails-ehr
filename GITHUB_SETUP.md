# GitHub Setup Instructions

## Option 1: Create New Repository via GitHub CLI

```bash
# Install GitHub CLI if needed
brew install gh

# Login
gh auth login

# Create new repository
gh repo create violet-rails-ehr --public --description "Rails-first EHR boilerplate with FHIR R4 API and Whoop integration"

# Update remote
git remote set-url origin https://github.com/YOUR_USERNAME/violet-rails-ehr.git

# Push
git push -u origin master
```

## Option 2: Create Repository via GitHub Web UI

1. Go to https://github.com/new
2. Repository name: `violet-rails-ehr`
3. Description: `Rails-first EHR boilerplate with FHIR R4 API and Whoop integration`
4. Public or Private: Choose based on preference
5. Don't initialize with README (we already have one)
6. Click "Create repository"

Then run:

```bash
# Update remote to your new repo
git remote set-url origin https://github.com/YOUR_USERNAME/violet-rails-ehr.git

# Push
git push -u origin master
```

## Option 3: Fork Original Violet Rails First

```bash
# Fork via GitHub CLI
gh repo fork restarone/violet_rails --clone=false --remote=false

# Add your fork as origin
git remote set-url origin https://github.com/YOUR_USERNAME/violet_rails.git

# Add upstream
git remote add upstream https://github.com/restarone/violet_rails.git

# Push your EHR additions
git push -u origin master
```

## Verify

```bash
git remote -v
# Should show your repository

git push
# Should push to your repo
```

## After Pushing

1. Update repository description on GitHub
2. Add topics: `fhir`, `ehr`, `rails`, `healthcare`, `whoop`
3. Update README.md to point to START_HERE.md
4. Add LICENSE file if needed
5. Enable GitHub Pages for documentation (optional)

## Recommended Repository Settings

- **About**: Rails-first EHR boilerplate with FHIR R4 API
- **Topics**: fhir, ehr, healthcare, rails, ruby, whoop, api, medical
- **License**: MIT (or your preference)
- **Issues**: Enabled
- **Wiki**: Enabled (for additional docs)
- **Discussions**: Enabled (for community)

