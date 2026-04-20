//
//  ContactView.swift
//  Riverhead NY Budget App
//
//  Improvements:
//  - Removes dependency on RiverheadURLs
//  - Adds "Open in Maps" for Town Hall
//  - Keeps your existing structure
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import MapKit
import UIKit

struct ContactView: View {
    @Environment(\.openURL) private var openURL

    private let townHallCoordinate = CLLocationCoordinate2D(latitude: 40.91734, longitude: -72.66298) // Riverhead Town Hall vicinity
    private let phoneURL = URL(string: "tel:6317273200")!
    private let contactURL = URL(string: "https://www.townofriverheadny.gov/142/Contact")!
    private let directoryURL = URL(string: "https://www.townofriverheadny.gov/directory.aspx")!

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.91734, longitude: -72.66298),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )

    var body: some View {
        List {
            Section {
                Map(position: $cameraPosition, interactionModes: [.all]) {
                    Marker("Riverhead Town Hall", coordinate: townHallCoordinate)
                        .tint(.red)
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } header: {
                Text("Town Hall")
            } footer: {
                Text("Town of Riverhead • 4 West Second Street • Riverhead, NY 11901")
            }

            Section("Contact") {
                Button {
                    openURL(phoneURL)
                } label: {
                    Label("Call Town Hall", systemImage: "phone.fill")
                }

                Button {
                    openInMaps()
                } label: {
                    Label("Open in Maps", systemImage: "map.fill")
                }

                NavigationLink {
                    WebContentView(url: contactURL, title: "Contact")
                } label: {
                    Label("Contact Page", systemImage: "link")
                }

                NavigationLink {
                    WebContentView(url: directoryURL, title: "Staff Directory")
                } label: {
                    Label("Staff Directory", systemImage: "person.2.fill")
                }
            }

            Section("Feedback") {
                NavigationLink {
                    ContactComposerView()
                } label: {
                    Label("Send App Feedback", systemImage: "envelope.fill")
                }
            }
        }
        .navigationTitle("Contact")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: townHallCoordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = "Riverhead Town Hall"
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

}

// MARK: - Simple feedback composer

private struct ContactComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""

    var body: some View {
        Form {
            Section("Message") {
                TextEditor(text: $message)
                    .frame(minHeight: 160)
            }

            Section {
                Button("Copy to Clipboard") {
                    UIPasteboard.general.string = message
                }
            } footer: {
                Text("This view copies your feedback message so you can paste it into an email or form. If you prefer, use the Contact Page link to reach the Town directly.")
            }
        }
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}
