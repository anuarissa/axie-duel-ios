import XCTest

/// Runs in the iOS simulator on CI: enters as a guest, then opens the main screens and saves screenshots
/// (to $AXD_SHOTS_DIR when set, and always as xcresult attachments) for the owner preview and the App Store.
final class AppUITests: XCTestCase {
    private var shotsDir: URL? {
        guard let dir = ProcessInfo.processInfo.environment["AXD_SHOTS_DIR"], !dir.isEmpty else { return nil }
        return URL(fileURLWithPath: dir, isDirectory: true)
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    private func shot(_ name: String) {
        let png = XCUIScreen.main.screenshot().pngRepresentation
        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = shotsDir {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try? png.write(to: dir.appendingPathComponent("\(name).png"))
        }
    }

    /// "Play as Guest" (iOS title screen) or "Enter as Guest" (current login page).
    private func guestButton(_ app: XCUIApplication) -> XCUIElement {
        let matchesGuest = NSPredicate(format: "label CONTAINS[c] %@", "Guest")
        return app.webViews.firstMatch.buttons.matching(matchesGuest).firstMatch
    }

    func testGuestAndMainScreens() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 60), "the game web view never appeared")
        sleep(6)
        shot("01-launch")

        let guest = guestButton(app)
        if guest.waitForExistence(timeout: 90) {
            guest.tap()
            sleep(12)
            shot("02-after-guest")
        } else {
            XCTFail("no Guest button on the first screen")
        }

        let paths = ["/dashboard", "/decks/builder", "/collection", "/store", "/play/pve"]
        for (index, path) in paths.enumerated() {
            app.terminate()
            app.launchArguments = ["-AXDStartPath", path]
            app.launch()
            sleep(14)
            let label = path.replacingOccurrences(of: "/", with: "_")
            shot(String(format: "%02d%@", index + 3, label))
        }
    }
}
