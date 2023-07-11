# Crisis Cleanup

## Setup
Reset package caches whenever modules are not found.

1. `brew install needle`
1. Install git hook(s) to prevent commits of unintended files and poor line spacing.
   - Xcode > Settings... > Text Editing > Editing > check While Editing checkboxes.
1. Copy/update expected files into App/CrisisCleanup/Config. This requires at least one Firebase project.
   - Set the correct values in App/Config/DebugConfig to accomodate local app development.
1. Configure scheme for local development.
   - Duplicate the App scheme and change the Run > Info > Build Configuration = Debug.
   - The app installed on the simulator/devices should have an black background for the app icon.

## Building and archiving
- Be sure to build from a completely clean state or run the build command twice on the scheme/configuration as Xcode uses cached files unexpectedly...