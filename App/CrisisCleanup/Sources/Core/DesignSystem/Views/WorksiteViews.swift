import MapKit
import SwiftUI

struct WorksiteNameView: View {
    let name: String

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(Color.gray)

            Text(name)
        }
    }
}

struct WorksiteAddressView<Content>: View where Content: View {
    let fullAddress: String
    @ViewBuilder let postView: () -> Content

    var body: some View {
        HStack {
            Image(systemName: "mappin")
                .foregroundColor(Color.gray)

            Text(fullAddress)
                .frame(maxWidth: .infinity, alignment: .leading)

            postView()
        }
    }
}

struct WorksiteCallButton: View {
    let phone1: String
    let phone2: String
    let enable: Bool
    let phoneNumberParser: PhoneNumberParser
    let onShowPhoneNumbers: ([ParsedPhoneNumber]) -> Void
    var tint: Color = .black

    var body: some View {
        let enableCall = enable && (phone1.isNotBlank || phone2.isNotBlank)
        Button {
            let parsedNumbers = phoneNumberParser.getPhoneNumbers([phone1, phone2])
            if parsedNumbers.count == 1,
               parsedNumbers.first?.parsedNumbers.count == 1 {
                let singleNumber = parsedNumbers.first!.parsedNumbers.first!
                let urlString =  "tel:\(singleNumber)"
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else {
                onShowPhoneNumbers(parsedNumbers)
            }
        } label : {
            Image(systemName: "phone.fill")
            // TODO: Common dimensions
                .frame(width: 75, height: 36)
                .fontHeader3()
                .roundedCorners()
        }
        .disabled(!enableCall)
        .tint(tint)
    }
}

struct WorksiteAddressButton: View {
    let addressMapItem: MKMapItem
    let enable: Bool
    var tint: Color = .black

    var body: some View {
        Button {
            addressMapItem.openInMaps()
        } label : {
            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
            // TODO: Common dimensions
                .frame(width: 75, height: 36)
                .fontHeader3()
                .roundedCorners()
        }
        .disabled(!enable)
        .tint(tint)
    }
}
