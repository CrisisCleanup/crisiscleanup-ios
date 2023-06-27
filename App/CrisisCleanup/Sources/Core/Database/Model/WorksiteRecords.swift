struct WorksiteRecords {
    let core: WorksiteRecord
    let flags: [WorksiteFlagRecord]
    let formData: [WorksiteFormDataRecord]
    let notes: [WorksiteNoteRecord]
    let workTypes: [WorkTypeRecord]
    let files: [NetworkFileRecord]

    init(
        _ core: WorksiteRecord,
        _ flags: [WorksiteFlagRecord],
        _ formData: [WorksiteFormDataRecord],
        _ notes: [WorksiteNoteRecord],
        _ workTypes: [WorkTypeRecord],
        _ files: [NetworkFileRecord] = []
    ) {
        self.core = core
        self.flags = flags
        self.formData = formData
        self.notes = notes
        self.workTypes = workTypes
        self.files = files
    }
}
