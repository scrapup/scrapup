<!--
The PR title MUST be a Conventional Commit — with squash merge it becomes the
commit on `main` and is what release-please parses to compute the next version.
Examples: `feat(skills): add inception brief layer` · `fix(forge): handle empty tasks.md`
-->

## Summary

<!-- What changes and why. Link the related spec / task / issue. -->

## Changes

-

## Evidence

<!-- "Done" requires observable verification — paste command output, validation
     results, or screenshots that show the change working. -->

## Checklist

- [ ] PR title follows Conventional Commits (`type(scope): subject`)
- [ ] Versioned artifacts are in English (code, skills, agents, docs, identifiers)
- [ ] If `README.md` changed, `README.pt.md` and `README.ja.md` are updated in this same PR
- [ ] No manual version bump — release-please owns `package.json`, `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- [ ] Breaking changes flagged with `!` or a `BREAKING CHANGE:` footer (if any)
