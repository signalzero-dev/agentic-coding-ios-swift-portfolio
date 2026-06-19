//
//  MovieBrowserTests.swift
//  MovieBrowserTests
//
//  The app target holds only the composition root and SwiftUI views; testable
//  logic lives in MovieBrowserCore. The one app-target unit is the UI-test
//  harness — these tests guard `StubMovieService` so a broken fixture fails fast
//  here rather than as a mysterious UI-test failure.
//

import Testing
import MovieBrowserCore
@testable import MovieBrowser

struct StubMovieServiceTests {

    @Test func popularReturnsSeededFixtures() async throws {
        let page = try await StubMovieService().popular(page: 1)
        #expect(page.results.count == 2)
        #expect(page.results.first?.title == "Stub Popular One")
    }

    @Test func searchReturnsSeededFixture() async throws {
        let page = try await StubMovieService().search(query: "stub", page: 1)
        #expect(page.results.map(\.title) == ["Stub Search Result"])
    }

    @Test func detailsReturnsSeededFixture() async throws {
        let details = try await StubMovieService().details(id: 1)
        #expect(details.title == "Stub Detail Title")
        #expect(details.overview == "Detail overview for the stub movie.")
    }
}
