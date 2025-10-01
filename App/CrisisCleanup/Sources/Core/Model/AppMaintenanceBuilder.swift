// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension AppMaintenance {
    // A default style constructor for the .copy fn to use
    init(
        ftsRebuildVersion: Int64,
        // This is to prevent overriding the default init if it exists already
        forCopyInit: Void? = nil
    ) {
        self.ftsRebuildVersion = ftsRebuildVersion
    }

    // struct copy, lets you overwrite specific variables retaining the value of the rest
    // using a closure to set the new values for the copy of the struct
    func copy(build: (inout Builder) -> Void) -> AppMaintenance {
        var builder = Builder(original: self)
        build(&builder)
        return builder.toAppMaintenance()
    }

    struct Builder {
        var ftsRebuildVersion: Int64

        fileprivate init(original: AppMaintenance) {
            self.ftsRebuildVersion = original.ftsRebuildVersion
        }

        fileprivate func toAppMaintenance() -> AppMaintenance {
            return AppMaintenance(
                ftsRebuildVersion: ftsRebuildVersion
            )
        }
    }
}
