//
//  MovieBrowserUITests.swift
//  MovieBrowserUITests
//
//  End-to-end flows for the core MovieBrowser journeys. These launch the app in
//  hermetic stub mode (`-uiTestStub`) so they exercise real navigation, search,
//  and detail rendering against deterministic fixtures — no TMDB token, no
//  network. See `RootContainer.makeUITestStub()` / `StubMovieService`.
//

import XCTest

final class MovieBrowserUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchStubbedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestStub"]
        app.launch()
        return app
    }

    @MainActor
    func testPopularListShowsMovies() throws {
        let app = launchStubbedApp()

        XCTAssertTrue(
            app.staticTexts["Stub Popular One"].waitForExistence(timeout: 10),
            "Popular list should render the first stub movie"
        )
        XCTAssertTrue(app.staticTexts["Stub Popular Two"].exists)
    }

    @MainActor
    func testTappingMovieOpensDetail() throws {
        let app = launchStubbedApp()

        XCTAssertTrue(app.staticTexts["Stub Popular One"].waitForExistence(timeout: 10))
        app.cells.firstMatch.tap()

        XCTAssertTrue(
            app.staticTexts["Detail overview for the stub movie."].waitForExistence(timeout: 10),
            "Tapping a movie should push its detail screen"
        )
    }

    @MainActor
    func testSearchShowsResults() throws {
        let app = launchStubbedApp()

        app.tabBars.buttons["Search"].tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("stub")

        XCTAssertTrue(
            app.staticTexts["Stub Search Result"].waitForExistence(timeout: 10),
            "Typing a query should show debounced search results"
        )
    }
}
