# Contributing

Modulo Squares is a private, closed-source project. It isn't open to outside contributions — there's no public issue tracker or pull request process for external contributors.

If you have collaborator access to this repository:

1. Branch from `develop` (`feature/<short-description>` or `fix/<short-description>`).
2. Keep commits focused, and write commit messages that explain *why*, not just *what*.
3. Run `flutter analyze` and `flutter test` in `packages/mobile` before opening a pull request.
4. Open the PR against `develop` and request review — don't merge your own changes without one. `develop` is promoted to `staging` and then `main` separately.

5. The Cloud Functions backend lives in a separate private repo, [modulo-squares-functions](../modulo-squares-functions) — scoring or purchase-verification changes belong there, not in this repo.

Questions about contributing should go to the repository owner (see SUPPORT.md).
