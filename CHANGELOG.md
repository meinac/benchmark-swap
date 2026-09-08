# Changelog

## Unreleased

- Verification no longer crashes the run when a returned value raises from `==` or from `inspect`. It reports a difference instead.
- An option that benchmark-ips does not know now raises `ArgumentError` instead of being ignored, so a typo no longer runs the benchmark with default settings.
- The list of swapped methods no longer crashes when a singleton method hangs on an object that raises from `to_s`.
- The warning shown when the two sides disagree has clearer wording.

## 0.1.0 (2026-09-08)

- First release.
