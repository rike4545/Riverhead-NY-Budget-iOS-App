//
//  SafariView.swift
//  Riverhead NY Budget App
//
//  Simple SwiftUI wrapper around SFSafariViewController.
//  Use this when you want a reliable in-app browser for external pages.
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    var entersReaderIfAvailable: Bool = false
    var barCollapsingEnabled: Bool = true

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = entersReaderIfAvailable
        config.barCollapsingEnabled = barCollapsingEnabled

        let vc = SFSafariViewController(url: url, configuration: config)
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // no-op
    }
}
