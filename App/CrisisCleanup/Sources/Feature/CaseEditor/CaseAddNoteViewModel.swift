import Foundation
import SwiftUI

class CaseAddNoteViewModel: ObservableObject {
    private let editableWorksiteProvider: EditableWorksiteProvider

    init(editableWorksiteProvider: EditableWorksiteProvider) {
        self.editableWorksiteProvider = editableWorksiteProvider
    }

    func onAddNote(_ note: String) {
        editableWorksiteProvider.editableWorksite.value = editableWorksiteProvider.editableWorksite.value.copy {
            var notes = $0.notes
            notes.append(WorksiteNote.create().copy { $0.note = note })
            $0.notes = notes
        }
    }
}
