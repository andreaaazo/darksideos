<h1 align="center">
   <img src="https://github.com/andreaaazo/darksideos/blob/main/docs/logo.png" width="200px">
   <br>
   <br>
   Contributing
   <br>
   <h4 align="center">
Development workflow, contribution rules, and pull request standards.
   </h4>
</h1>

<p align="center">
  <a href="#how-to-contribute">How To Contribute</a> •
  <a href="#first-time-setup">First-Time Setup</a> •
  <a href="#naming-conventions">Naming Conventions</a> •
  <a href="#standard-workflow">Standard Workflow</a> •
  <a href="#creating-a-branch">Creating a Branch</a> •
  <a href="#writing-commit-messages">Writing Commit Messages</a> •
  <a href="#work-in-progress">Work In Progress</a> •
  <a href="#opening-a-pull-request">Opening a Pull Request</a> •
  <a href="#label-usage-policy">Label Usage Policy</a> •
  <a href="#merging-branches">Merging Branches</a> •
  <a href="#code-owners-and-reviews">Code Owners and Reviews</a> •
  <a href="#keep-branch-updated">Keep Branch Updated</a> •
  <a href="#repository-governance-files">Repository Governance Files</a> •
  <a href="#quick-example">Quick Example</a>
</p>

---

## How To Contribute
Welcome to the DarksideOS contribution guide.

This repository follows a structured workflow to keep the codebase clean, consistent, and production-ready.
Before contributing, please read and follow the guidelines below.

### Mandatory Rules

Before contributing, make sure you follow these rules:

- Work only through Pull Requests
- Do not push directly to the `main` branch
- Use signed and verified commits
- Use Conventional Commit messages
- Use a valid Pull Request title
- Wait for all required checks and reviews before merge
- Merge only with squash
- Complete the pull request template before requesting review
- Respect automated and manual label usage rules

---

## First-Time Setup
### 1 Clone the repository
This must be done **only** on SSH:
```bash
git clone git@github.com:andreaaazo/darksideos.git
cd darksideos
```
### 2 Configure Git Identity
```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### 3 Configure Signed Commits
This repository requires **verified signed commits**. Unsigned commits cannot be merged.

You have to use **SSH signing**, configure Git like this:

```bash
git config --global gpg.format ssh
git config --global user.signingkey your_ssh_key_path
git config --global commit.gpgsign true
```

Then add the same public key to GitHub as a `Signing Key`.

After setup, all new commits should be signed automatically.

Verify your configuration with:

```bash
git config --global --get gpg.format # Output: ssh
git config --global --get user.signingkey # Output: Path to key
git config --global --get commit.gpgsign # Output: true
```

---

## Naming Conventions
To maintain a clean and readable history, this repository enforces a consistent naming convention based on Conventional Commits.

This applies to:
- Branch names
- PR titles
- Commit messages

### Branch format
Format: `type/short-subject-description`

### PR Titles and Commit messages
Format: `type(scope): subject`

### Rules

* `type` must be valid
* `scope` is required
* `subject` must be lowercase
* `subject` must not end with punctuation

### Allowed types

* `feat` - A new feature
* `fix` - A bug fix
* `docs` - Documentation only changes
* `style` - Formatting, missing semi-colons, etc.
* `refactor` - Code change that neither fixes a bug nor adds a feature
* `perf` - A code change that improves performance
* `test` - Adding missing tests or correcting existing tests
* `ci` - Changes to CI configuration files and scripts
* `chore` - Other changes that don't modify `src` or `test` files
* `revert` - Reverts a previous commit

---

## Standard Workflow
All changes must go through a **Pull Request**.

Direct changes to the `main` branch are not allowed.
Every contribution must be developed on a separate branch, pushed to GitHub, and merged through a reviewed Pull Request.

1. Pull the latest changes from the `main` branch
2. Create a feature branch
3. Work locally
4. Commit **using the required commit format**
5. Push your branch
6. Open a Pull Request
7. Wait for checks and required reviews
8. Merge using **Squash Merge**

---

## Creating a Branch
Always branch off from the `main` branch.

```bash
git checkout main # Go to main branch
git pull origin main # Pull from main
git checkout -b feat/your-feature-name # Create new branch (duplicate from main)
```

### Branch Naming
Make sure the branch name follows our rules in: [`Naming Conventions`](#naming-conventions)

#### Examples
Use clear and descriptive names:

* `feat/add-auth-flow`
* `fix/login-validation`
* `docs/update-readme`
* `ci/add-pr-title-check`

---

## Writing Commit Messages
This repository enforces **Conventional Commits**. Make sure **every commit** follows the rules described in [`Naming Conventions`](#naming-conventions).

If your commit fails validation, you can change the last commit message:

```bash
git commit --amend -m "docs(repo): update onboarding guide"
git push --force-with-lease
```

---

## Work In Progress
If you haven't finished your feature, **do not wait until the end to push**. Keep working on your current branch and use GitHub's **Draft Pull Request** feature.

### How to handle incomplete work:
1. Commit your current progress locally (e.g., `chore(ios): save current bluetooth radar progress`).
2. Push your branch to GitHub: `git push -u origin your-branch-name`
3. Open a Pull Request, but click the dropdown next to the submit button and select **Create Draft Pull Request**.

### Why we use Draft PRs:
* **Safe Backup:** Your work is safely stored on the server.
* **Early CI Feedback:** GitHub Actions will run on your partial code at every push, catching errors early.
* **No Accidental Merges:** The merge action is disabled while the pull request is in Draft mode.
* **Reduced Review Noise:** Code Owners are not notified until the work is ready for review.

When your work is fully complete, click **Ready for review** on GitHub to notify the team and enable the merge button.

---

## Opening a Pull Request

When your work is ready:

1. Push your branch

```bash
git push -u origin your-branch-name
```

2. Open a Pull Request against the `main` branch
3. Use a valid PR title
4. Resolve all review comments
5. Wait for all required checks to pass
6. Ensure the pull request template is completed accurately
7. Verify that automatically applied labels correctly reflect the scope of the change

### PR Titles
**Pull Request titles are also validated.**
GitHub may prefill the title, but you are responsible for ensuring it matches the required format.
Make sure the Pull Request title follows our rules in: [`Naming Conventions`](#naming-conventions)

#### Valid examples

```text
feat(auth): add password reset flow
fix(api): handle missing token edge case
docs(repo): improve contribution guide
```

#### Invalid examples

```text
Add password reset flow
Fix auth issue
docs(repo): Improve docs.
```

---

## Label Usage Policy

This repository uses a combination of automatic and manual labels for pull requests and issues.

### Automatic Labels

Some labels are applied automatically by repository automation:

- **Issue templates** automatically apply:
  - `bug`
  - `feature`
  - `improvement`

- **PR labeler** automatically applies labels based on the files changed in a pull request, including:
  - `server`
  - `ios`
  - `android`
  - `kmm`
  - `reports`
  - `ci`
  - `docs`
  - `dependencies`
  - `config`
  - `tests`
  - `chore`

These labels are managed by repository automation and should not be modified manually unless required.

### Manual Labels

The following labels are intended for manual workflow usage:

- `needs-triage`
- `needs-info`
- `blocked`
- `in-progress`
- `ready-for-review`
- `security`
- `performance`
- `refactor`

Use manual labels only when they accurately reflect the current state or purpose of the issue or pull request.

---

## Merging Branches
This repository uses only **Squash Merge**.

That means all commits in the Pull Request are combined into a single commit when merged into the `main` branch.

### Why we use Squash Merge

* cleaner history
* easier rollback
* one commit per completed change
* better traceability in production

Before merging, **make sure the final PR title is correct**, because it may become the final commit message on the `main` branch.

---

## Code Owners and Reviews

This repository uses **Code Owners**.

Directories are owned by specific developers or teams. You can find the specific ownership rules and mapped areas in the [`.github/CODEOWNERS`](.github/CODEOWNERS) file.

**If your Pull Request modifies files inside an owned area, GitHub requires review from the corresponding code owner before the PR can be merged.**

### What this means
* If you modify files owned by another developer, their review will be required before merge.
* If you work in your own area, follow the repository rules and approval flow defined in the repository settings.
* Do not merge until all required reviews are completed

---

## Keep Branch Updated
Branch protection requires branches to be up to date before merging. Before using Squash Merge, update your branch with the latest changes from `main`.

Example to keep it updated with the latest `main` branch:

```bash
git checkout main
git pull origin main
git checkout your-branch-name
git rebase main
git push --force-with-lease
```

---

## Repository Governance Files

This repository includes a standard governance and security baseline.

The following files and configurations are part of the expected contribution workflow:

- [`CONTRIBUTING.md`](./CONTRIBUTING.md) for contribution standards and workflow rules
- [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md) for collaboration and review behavior standards
- [`SECURITY.md`](./SECURITY.md) for security reporting instructions
- `LICENSE` for copyright and usage restrictions
- [`.github/CODEOWNERS`](./.github/CODEOWNERS) for ownership and required review routing
- pull request and issue templates for standardized contribution intake
- automated labels and review checks for pull request classification and policy enforcement
- [`.github/pull_request_template.md`](./.github/pull_request_template.md) for standardized pull request descriptions

---

## Quick Example

### Full Workflow with a Draft Pull Request

```bash
# 1. Start from main
git checkout main
git pull origin main
git checkout -b feat/add-auth-flow

# 2. Commit initial work
git add .
git commit -m "chore(auth): add initial login screen structure"
git push -u origin feat/add-auth-flow
```

Then:

* Open a **Draft Pull Request** on GitHub.
* Complete the pull request template.
* Confirm the PR title follows the required convention, for example: `feat(auth): add auth flow`.

```bash
# 3. Continue development
git add .
git commit -m "feat(auth): integrate login api"
git push origin feat/add-auth-flow
```

Then:

* Mark the Draft Pull Request as **Ready for review**.
* Wait for all required checks to pass.
* Wait for required Code Owner approvals.
* Verify labels and review feedback.
* Merge using **Squash Merge**.