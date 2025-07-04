// Values must match those in Info.plist
enum BackgroundTaskType: String {
    case refresh = "com.crisiscleanup.refresh"
    case pushWorksites = "com.crisiscleanup.upload_worksite_changes"
    case pushWorksiteMedia = "com.crisiscleanup.upload_worksite_media"
    case clearInactive = "com.crisiscleanup.clear_inactive"
}
