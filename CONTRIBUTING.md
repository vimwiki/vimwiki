# Contributing to Vimwiki

# Filing a bug

Before filing a bug or starting to write a patch, check the latest development version from
https://github.com/vimwiki/vimwiki/tree/dev to see if your problem is already fixed.

Issues can be filed at https://github.com/vimwiki/vimwiki/issues/ .

# Creating a pull request

If you want to provide a pull request on GitHub, please start from the `dev` branch, not from the
`master` branch. (Caution, GitHub shows `master` as the default branch from which to start a PR.)

Make sure to update `doc/vimwiki.txt` with the following information:

<<<<<<< HEAD
1. Update the changelog to include, at the top of it, information on the new feature
   the PR introduces or the bug it is fixing as well as the PR number and related issue number
   if possible
2. Add a help section to describe any new features or options.
3. If you are a first time contributor add your name to the list of contributors.
4. Add some non regression tests on:
  - The bug you fixed
  - The new feature you added
  - The API function you added or changed
=======
1. Update the changelog to include information on the new feature the PR introduces or the bug it
   is fixing.
2. Add a help section to describe any new features or options.
3. If you are a first time contributor add your name to the list of contributors.
>>>>>>> Bump version number – release 2.5

**Testing:** Vimwiki uses [vader](https://github.com/junegunn/vader.vim) for unit tests and
[vint](https://github.com/Kuniwak/vint) for linting. Any new PRs must add new tests and pass all
linter checks. See the [test README](test/README.md) for more info.

- In addition to the included tests, there are more example wikis that can be used for testing
  [here](https://github.com/vimwiki/testwikis).

# More info and advice for (aspiring) core developers

- Before implementing a non-trivial feature, think twice what it means for the user. We should
  always try to keep backward compatibility. If you are not sure, discuss it on GitHub.
- Also, when thinking about adding a new feature, it should be something which fits into the
  overall design of Vimwiki and which a significant portion of the users may like. Keep in mind
  that everybody has their own way to use Vimwiki.
- Keep the coding style consistent.
- Test your changes. Keep in mind that Vim has a ton of options and the users tons of different
  setups. Take a little time to think about under which circumstances your changes could break.

## Git branching model

- There are two branches with eternal lifetime:
    1. `dev`: This is where the main development happens. Tasks which are done in one or only a few
       commits go here directly. Always try to keep this branch in a working state, that is, if the
       task you work on requires multiple commits, make sure intermediate commits don't make
       Vimwiki unusable (or at least push these commits at one go).
    2. `master`: This branch is for released states only. Whenever a reasonable set of changes has
       piled up in the `dev` branch, a [release is done](#preparing-a-release). After a release,
       `dev` has been merged into `master` and `master` got exactly one additional commit in which
       the version number in `plugin/vimwiki.vim` is updated. Apart from these commits and the
       merge commit from `dev`, nothing happens on `master`. Never should `master` merge into
       `dev`. When the users ask, we should recommend this branch for them to use.
- Larger changes which require multiple commits are done in feature branches. They are based on
  `dev` and merge into `dev` when the work is done.

## Preparing a release

1. `git checkout dev`
2. Update the changelog in the doc, nicely grouped, with a new version number and release date.
3. Update the list of contributors.
4. Update the version number at the top of the doc file.
5. If necessary, update the Readme and the home page.
6. `git checkout master && git merge dev`
7. Update the version number at the top of plugin/vimwiki.vim.
8. Set a tag with the version number in Git: `git tag vX.Y`
9. `git push --tags`
10. In GitHub, go to _Releases_ -> _Draft a new release_ -> choose  the tag, convert the changelog
    from the doc to markdown and post it there. Make plans to build an automatic converter and
    immediately forget this plan.
11. Tell the world.

<<<<<<< HEAD
<!-- vim: set tw=99 : -->
=======
<!-- vim:tw=99 -->
>>>>>>> Bump version number – release 2.5
