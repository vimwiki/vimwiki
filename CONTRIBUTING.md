# Contributing to VimWiki

# Filing a bug

Before filing a bug or starting to write a patch, check the latest development
version from https://github.com/vimwiki/vimwiki/tree/dev to see if your problem
is already fixed.

Issues can be filed at https://github.com/vimwiki/vimwiki/issues/

# Git branching model

As of v2022.12.02, VimWiki has adopted a rolling release model, along with
[calendar versioning][calver].  A release should be
[prepared][#preparing-a-release] for every change or set of changes which merge
to `dev`.

[calver]: https://calver.org/

There are two permanent branches:
    1. `dev`: This is the default branch, and where changes are released. Tasks
       which are done in one or only a few commits go here directly. Always
       keep this branch in a working state. If the task you work on requires
       multiple commits, make sure intermediate commits don't make VimWiki
       unusable.
    2. `master`: This is a legacy branch, retained to avoid breaking existing
       checkouts of the plugin.  It should be kept in sync with `dev`.

Large changes which require multiple commits may be authored in feature
branches, and merged into `dev` when the work is done.

# Creating a pull request

If you want to provide a pull request on GitHub, start from the `dev` branch,
not from the `master` branch.

Version bureaucracy:

1. Pick a new version number according to the current date:
   `YYYY.MM.DD` (if releasing a second version for the
   current date, append a `_MICRO` version such as `_1`, `_2`, etc.
   - Examples: `2022.12.22`, `2022.12.22_1`
2. Update the version number at the top of `plugin/vimwiki.vim`
3. Update the `!_TAG_PROGRAM_VERSION` expected in `test/tag.vader`
   (this is a bit silly, will have to figure out how to get rid of it)

Update `doc/vimwiki.txt` with the following information:

1. Update the changelog to include, at the top of it, information on the new
   feature the PR introduces or the bug it is fixing as well as the PR number
   and related issue number if possible.
2. Add a help section to describe any new features or options.
3. If you are a first time contributor add your name to the list of
   contributors.

# Preparing a release

This section is primarily for maintainers.

1. Set a tag with the version number in Git: `git tag -a v2022.12.02 -m 'Release v2022.12.02'`
2. `git push --tags`
3. In GitHub, go to _Releases_ -> _Draft a new release_ -> choose the tag,
   convert the changelog from the doc to Markdown and post it there. Make
   plans to build an automatic converter and immediately forget this plan.
4. If necessary, update `README.md` and the home page.
5. For major changes: Tell the world.

[semver]: https://semver.org/
