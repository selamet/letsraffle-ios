import XCTest
@testable import Lets_Raffle

final class ReviewPromptTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "ReviewPromptTests")
        defaults.removePersistentDomain(forName: "ReviewPromptTests")
    }

    func testAsksOncePerVersion() {
        let first = ReviewPrompt(defaults: defaults, version: "1.0.2")
        XCTAssertTrue(first.shouldAsk)
        first.markAsked()
        XCTAssertFalse(ReviewPrompt(defaults: defaults, version: "1.0.2").shouldAsk)
    }

    func testAsksAgainAfterAnUpdate() {
        ReviewPrompt(defaults: defaults, version: "1.0.2").markAsked()
        XCTAssertTrue(ReviewPrompt(defaults: defaults, version: "1.0.3").shouldAsk)
    }
}
