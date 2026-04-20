//
//  HowDoIView.swift
//  Riverhead NY Helper
//

import SwiftUI

@MainActor
struct HowDoIView: View {
    var body: some View {
        WebContentView(url: RiverheadURLs.howDoI)
            .navigationTitle("How Do I…")
            .navigationBarTitleDisplayMode(.inline)
            .background(RiverheadTheme.background)
            .ignoresSafeArea(edges: .bottom)
    }
}
