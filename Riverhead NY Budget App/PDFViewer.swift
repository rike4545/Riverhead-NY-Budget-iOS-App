//
//  PDFViewer.swift
//  Riverhead NY Budget App
//
//  Simple wrapper around PDFKit’s PDFView for local/bundled PDFs.
//  iOS 17+ / Swift 6
//

import SwiftUI
import PDFKit

// MARK: - High-level SwiftUI wrapper

struct PDFViewer: View {
    /// Name of the resource in your app bundle (without extension)
    let resourceName: String
    /// File extension, usually "pdf"
    let resourceExtension: String
    /// Optional nav/title to show in parent NavigationStack
    let title: String

    /// Default init keeps your existing behavior:
    /// loads "Riverhead_2026_Prelim.pdf" from the main bundle.
    init(
        resourceName: String = "Riverhead_2026_Prelim",
        resourceExtension: String = "pdf",
        title: String = "2026 Preliminary Budget"
    ) {
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
        self.title = title
    }

    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension),
               let doc = PDFDocument(url: url) {
                PDFKitView(document: doc)
            } else {
                ContentUnavailableView(
                    "PDF not found",
                    systemImage: "doc.richtext",
                    description: Text("Make sure \(resourceName).\(resourceExtension) is included in the app bundle.")
                )
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - PDFKit bridge

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()

        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.backgroundColor = .systemBackground

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // No dynamic updates needed for now; document is fixed.
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PDFViewer()
    }
}
