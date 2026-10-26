We're going to implement the big plan at https://claude.ai/artifact/4EeeTMEzXaZ39ppQ26ibwR.

This big plan breaks down a chunk of work into self-contained PRs.

For each commit, you're going to work in plan mode to produce a detailed plan, which we will iterate on together before you implement.

We might make multiple commits for a PR.

For each commit, I will also expect:

* commit-message.txt containing a proposed commit message
* validation-instructions.txt, containing instructions for me to validate, including any one-off prerequisites (eg setting up accounts) that the commit first needs

For the last commit of a PR with multiple commits, or of any PR that changes OpenTofu config, I will also expect:

* pr-description.txt, containing a PR title and description covering the whole PR

PR descriptions don't include command output (such as `just plan`), and validation instructions don't ask for it to be kept.

These files are overwritten each time and are gitignored.

Before each commit:

* check that the README is accurate and coherent
* check that the new changes are minimal and self-consistent

I run all commands and make all commits; you only edit files.

`main` is protected, so each PR is developed on a branch. Don't push or open the PR until its last commit is made.

The big plan is a guide, and we may want to change how we work as we go. Leave the big plan as it is, and don't refer to changes to it in the README or in commit messages.

A general principle: we should introduce a bit of functionality in one commit, and then elaborate on it (eg add resilience) in a subsequent commit. This applies both to commits within a PR and to splitting PRs.
