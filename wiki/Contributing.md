# Contributing to Immersive Air Wing Namelists

## Development Workflow
1. Clone the repository.
2. Run `build.ps1 -DevLink` to link the mod directly to your Hearts of Iron IV launcher.
3. Make your modifications.
4. After editing anything in `localisation/english/`, run `build.ps1 -SyncLoc` to regenerate the other nine game languages, and commit the generated files.
5. Execute validation with `build.ps1 -ValidateOnly` and tests with `build.ps1 -Test`.
