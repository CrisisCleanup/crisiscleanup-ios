import SwiftUI

struct SurvivorNoteLegend: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var body: some View {
        HStack {
            Spacer()
            Image(systemName: "circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(appTheme.colors.survivorNoteColorNoTransparency)
            Text(t.t("formLabels.survivor_notes"))
        }
    }
}

struct StaticNotesList: View {
    let notes: [WorksiteNote]

    var body: some View {
        let idNotes: [(Int64, WorksiteNote)] = notes.map { note in
            let id = note.id > 0 ? note.id : Int64(note.createdAt.timeIntervalSince1970)
            return (id, note)
        }
        ForEach(idNotes, id: \.0) { idNote in
            let note = idNote.1
            VStack(alignment: .leading, spacing: appTheme.gridItemSpacing) {
                Text(note.createdAt.relativeTime)
                    .fontBodySmall()
                StaticHtmlTextView(htmlContent: note.note)
            }
            .listItemModifier()
            .background(note.isSurvivor ? appTheme.colors.survivorNoteColorNoTransparency : .white)
        }
    }
}
