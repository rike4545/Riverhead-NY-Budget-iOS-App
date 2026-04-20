import SwiftUI
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@MainActor
struct AdMobBannerContainerView: View {
    let adUnitID: String
    var showDebugPlaceholder: Bool = false

    @State private var adHeight: CGFloat = 0
    @State private var hasResponse: Bool = false
    @State private var refreshNonce: Int = 0

    private var isLoaded: Bool { adHeight > 0 }
    private var shouldShowStatusUI: Bool {
        #if DEBUG
        return showDebugPlaceholder && hasResponse && !isLoaded
        #else
        return false
        #endif
    }

    private var shouldShowContainer: Bool {
        isLoaded || shouldShowStatusUI
    }

    var body: some View {
        VStack(spacing: 6) {
            if shouldShowContainer {
                Text("Sponsored")
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.primary.opacity(0.08))
                    )
                    .accessibilityHidden(true)
            }

            if shouldShowStatusUI {
                HStack(spacing: 8) {
                    Text("Ad unavailable right now")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    #if DEBUG
                    Button("Retry") {
                        hasResponse = false
                        refreshNonce += 1
                    }
                    .font(.caption.weight(.semibold))
                    #endif
                }
                .padding(.horizontal, 10)
            }

            BannerRepresentable(adUnitID: adUnitID) { loaded, height in
                withAnimation(.easeInOut(duration: 0.2)) {
                    hasResponse = true
                    adHeight = loaded ? max(height, 50) : 0
                }
            }
            .id(refreshNonce)
            .frame(height: isLoaded ? adHeight : 0)
            .opacity(isLoaded ? 1 : 0)
        }
        .padding(.horizontal, shouldShowContainer ? 8 : 0)
        .padding(.vertical, shouldShowContainer ? 6 : 0)
        .background {
            if shouldShowContainer {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.secondary.opacity(0.45), lineWidth: 1)
                    )
            }
        }
        .accessibilityHidden(!shouldShowContainer)
        .onAppear {
            if !hasResponse {
                refreshNonce += 1
            }
        }
    }
}

#if canImport(GoogleMobileAds)
private struct BannerRepresentable: UIViewControllerRepresentable {
    let adUnitID: String
    let onStateChange: @MainActor (_ loaded: Bool, _ height: CGFloat) -> Void

    func makeUIViewController(context: Context) -> BannerHostViewController {
        BannerHostViewController(adUnitID: adUnitID, onStateChange: onStateChange)
    }

    func updateUIViewController(_ uiViewController: BannerHostViewController, context: Context) {
        uiViewController.updateAdStateCallback(onStateChange)
        uiViewController.updateAdUnitID(adUnitID)
        uiViewController.loadBannerIfNeeded()
    }
}

private final class BannerHostViewController: UIViewController {
    private let bannerView = GADBannerView()
    private var adUnitID: String
    private var onStateChange: @MainActor (_ loaded: Bool, _ height: CGFloat) -> Void
    private var lastLoadedWidth: CGFloat = 0
    private var hasAttemptedInitialLoad = false

    init(
        adUnitID: String,
        onStateChange: @escaping @MainActor (_ loaded: Bool, _ height: CGFloat) -> Void
    ) {
        self.adUnitID = adUnitID
        self.onStateChange = onStateChange
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = self
        bannerView.delegate = self

        view.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerView.topAnchor.constraint(equalTo: view.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadBannerIfNeeded(force: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadBannerIfNeeded(force: !hasAttemptedInitialLoad)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        loadBannerIfNeeded(force: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.loadBannerIfNeeded(force: true)
        }
    }

    func updateAdStateCallback(
        _ callback: @escaping @MainActor (_ loaded: Bool, _ height: CGFloat) -> Void
    ) {
        onStateChange = callback
    }

    func updateAdUnitID(_ adUnitID: String) {
        guard bannerView.adUnitID != adUnitID else { return }
        self.adUnitID = adUnitID
        bannerView.adUnitID = adUnitID
        lastLoadedWidth = 0
    }

    func loadBannerIfNeeded(force: Bool = false) {
        let availableWidth = floor(view.frame.inset(by: view.safeAreaInsets).width)
        guard availableWidth > 0 else { return }

        guard force || abs(lastLoadedWidth - availableWidth) >= 1 else { return }
        hasAttemptedInitialLoad = true
        lastLoadedWidth = availableWidth

        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(availableWidth)
        bannerView.load(GADRequest())
    }
}

extension BannerHostViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        let height = bannerView.adSize.size.height
        Task { @MainActor in
            onStateChange(true, height)
        }
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor in
            onStateChange(false, 0)
        }
    }
}
#else
private struct BannerRepresentable: View {
    let adUnitID: String
    let onStateChange: @MainActor (_ loaded: Bool, _ height: CGFloat) -> Void

    var body: some View {
        EmptyView()
            .task {
                await MainActor.run {
                    onStateChange(false, 0)
                }
            }
    }
}
#endif

private struct AdMobBannerPlacementModifier: ViewModifier {
    var showDebugPlaceholder: Bool = false

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AdMobBannerContainerView(
                    adUnitID: AdMobConfig.bannerAdUnitID,
                    showDebugPlaceholder: showDebugPlaceholder
                )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 2)
            }
    }
}

extension View {
    @MainActor
    func adMobBannerPlacement(showDebugPlaceholder: Bool = false) -> some View {
        modifier(AdMobBannerPlacementModifier(showDebugPlaceholder: showDebugPlaceholder))
    }
}
