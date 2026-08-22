//
//  TestScrollHelpers.swift
//  TestBed-GPTDriverTests
//
//  Small XCUITest helpers shared across hybrid tests. XCUITest has
//  no built-in "scroll until visible" primitive — elements below
//  the fold must be scrolled into view before they become hittable.
//  These helpers do that by swiping up on the first table (or
//  scrollView) until the element is visible, with a bounded number
//  of retries.
//

import XCTest

enum TestScrollHelpers {
    /// Polls the given element and swipes up on the main scrolling
    /// container until the element becomes hittable or the maxSwipes
    /// budget is exhausted. Silently succeeds if the element is
    /// already visible.
    static func scrollUntilVisible(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxSwipes: Int = 8
    ) {
        if element.exists, element.isHittable { return }

        let scrollContainer = firstScrollingContainer(in: app)
        var swipes = 0
        while swipes < maxSwipes {
            if element.exists, element.isHittable { return }
            scrollContainer.swipeUp()
            swipes += 1
        }

        // Last-resort existence wait so the caller's subsequent tap
        // fails with a clear message rather than a silent no-op.
        _ = element.waitForExistence(timeout: 2)
    }

    private static func firstScrollingContainer(in app: XCUIApplication) -> XCUIElement {
        let table = app.tables.firstMatch
        if table.exists { return table }

        let collection = app.collectionViews.firstMatch
        if collection.exists { return collection }

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists { return scrollView }

        return app
    }
}
