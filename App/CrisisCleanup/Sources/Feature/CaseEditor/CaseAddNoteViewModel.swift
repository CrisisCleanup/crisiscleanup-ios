import Foundation
import SwiftUI

class CaseAddNoteViewModel: ObservableObject {
    private let editableWorksiteProvider: EditableWorksiteProvider

    init(editableWorksiteProvider: EditableWorksiteProvider) {
        self.editableWorksiteProvider = editableWorksiteProvider
    }

    func onAddNote(_ note: String) {
        editableWorksiteProvider.addNote(note)
    }
}
