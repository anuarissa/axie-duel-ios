import UIKit
import WebKit
import Capacitor

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()

        SceneDelegateProxy.shared.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        SceneDelegateProxy.shared.scene(scene, openURLContexts: URLContexts)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        SceneDelegateProxy.shared.scene(scene, continue: userActivity)
    }
}

/// The Capacitor bridge plus a few native touches for a landscape card game.
final class MainViewController: CAPBridgeViewController {
    private var navigationFilter: NavigationErrorFilter?

    override func capacitorDidLoad() {
        super.capacitorDidLoad()
        // Capacitor shows the offline page for every failed navigation; ignore the benign ones (see NavigationErrorFilter).
        if let webView = webView, let handler = webView.navigationDelegate as? WebViewDelegationHandler {
            let filter = NavigationErrorFilter(target: handler)
            navigationFilter = filter
            webView.navigationDelegate = filter
        }
    }

    // A swipe from the bottom edge (where the card hand is) should not leave the game on the first try.
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    #if DEBUG
    // UI tests open a specific screen with the launch argument `-AXDStartPath /collection` (Debug builds only).
    override func instanceDescriptor() -> InstanceDescriptor {
        let descriptor = super.instanceDescriptor()
        if let path = UserDefaults.standard.string(forKey: "AXDStartPath"), path.hasPrefix("/") {
            let joiner = path.contains("?") ? "&" : "?"
            descriptor.serverURL = "https://axie-duel.com\(path)\(joiner)src=ios"
        }
        return descriptor
    }
    #endif
}

/// Capacitor loads `server.errorPath` for ANY failed navigation, including cancelled ones (NSURLErrorCancelled, -999) and
/// "frame load interrupted" (WebKitErrorDomain 102). Both happen while online when one navigation replaces another, so they
/// must not show "You're offline". Everything else is forwarded untouched to Capacitor's own delegate.
final class NavigationErrorFilter: NSObject, WKNavigationDelegate {
    private let target: WebViewDelegationHandler

    init(target: WebViewDelegationHandler) {
        self.target = target
        super.init()
    }

    static func isBenign(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return true }
        if nsError.domain == "WebKitErrorDomain" && nsError.code == 102 { return true }
        return false
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if NavigationErrorFilter.isBenign(error) { return }
        target.webView(webView, didFail: navigation, withError: error)
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if NavigationErrorFilter.isBenign(error) { return }
        target.webView(webView, didFailProvisionalNavigation: navigation, withError: error)
    }

    override func responds(to aSelector: Selector!) -> Bool {
        return super.responds(to: aSelector) || target.responds(to: aSelector)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target.responds(to: aSelector) ? target : super.forwardingTarget(for: aSelector)
    }
}
