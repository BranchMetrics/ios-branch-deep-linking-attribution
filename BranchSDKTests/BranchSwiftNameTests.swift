//
//  BranchSwiftNameTests.swift
//  BranchSDKTests
//
//  Copyright © 2025 Branch, Inc. All rights reserved.
//

import XCTest
import UIKit
import BranchSDK

/// Coverage for the `NS_SWIFT_NAME` / `NS_SWIFT_ASYNC_NAME` annotations on `Branch.h` and
/// `BranchEvent.h`.
///
/// Most of the work here is done by the *compiler*: each test binds the annotated method to a
/// local constant with a fully written-out type. If a Swift name is renamed, dropped, or if the
/// importer starts producing a different signature (for example an optional return, or a `Bool`
/// where we expected `Void`), this file stops compiling. That is the point — a header edit that
/// would silently break every Swift integration becomes a build failure in CI instead.
///
/// Each test also asserts the underlying Objective-C selector is unchanged, because
/// `NS_SWIFT_NAME` renames only the Swift projection: any change to the selector string itself
/// would be a breaking change for Objective-C callers.
///
/// `@available(iOS 13.0, *)`: the test target deploys to iOS 12, and Swift concurrency
/// back-deploys only to iOS 13.
/// Note: this class is intentionally *not* `@MainActor`. Under the Swift 6 language mode used by
/// this target, `Branch` and `BranchEvent` import as non-Sendable, so referencing or awaiting a
/// nonisolated `async` method from a main-actor context is an error ("non-sendable type 'Branch'
/// cannot exit main actor-isolated context"). The individual tests that need main-actor APIs
/// (`waitForExpectations`) are annotated instead.
@available(iOS 13.0, *)
final class BranchSwiftNameTests: XCTestCase {

    /// Same key the Objective-C suites use. `+initialize:` is guarded, so a second call from
    /// another suite just warns and returns the existing singleton.
    private static let testKey = "key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"

    private var branch: Branch!

    override func setUpWithError() throws {
        try super.setUpWithError()
        branch = Branch.initialize(BranchConfiguration(key: Self.testKey))
    }

    override func tearDownWithError() throws {
        branch = nil
        try super.tearDownWithError()
    }

    // MARK: - NS_SWIFT_NAME: callback variants

    /// `requestDeepLinkData:callback:` → `requestDeepLinkData(branchLink:callback:)`
    func testSwiftNameRequestDeepLinkDataBranchLinkCallback() {
        let method: (String?, (([AnyHashable: Any]?, Error?) -> Void)?) -> Void =
            branch.requestDeepLinkData(branchLink:callback:)
        _ = method

        let selector = #selector(Branch.requestDeepLinkData(branchLink:callback:))
        XCTAssertEqual(NSStringFromSelector(selector), "requestDeepLinkData:callback:")
        XCTAssertTrue(branch.responds(to: selector))
    }

    /// `requestDeepLinkDataWithLaunchOptions:callback:` → `requestDeepLinkData(launchOptions:callback:)`
    func testSwiftNameRequestDeepLinkDataLaunchOptionsCallback() {
        let method: ([AnyHashable: Any]?, (([AnyHashable: Any]?, Error?) -> Void)?) -> Void =
            branch.requestDeepLinkData(launchOptions:callback:)
        _ = method

        let selector = #selector(Branch.requestDeepLinkData(launchOptions:callback:))
        XCTAssertEqual(NSStringFromSelector(selector), "requestDeepLinkDataWithLaunchOptions:callback:")
        XCTAssertTrue(branch.responds(to: selector))
    }

    #if !os(tvOS)
    /// `requestDeepLinkDataWithSceneOptions:scene:callback:` → `requestDeepLinkData(sceneOptions:scene:callback:)`
    func testSwiftNameRequestDeepLinkDataSceneOptionsSceneCallback() {
        let method: (UIScene.ConnectionOptions?, UIScene, (([AnyHashable: Any]?, Error?) -> Void)?) -> Void =
            branch.requestDeepLinkData(sceneOptions:scene:callback:)
        _ = method

        let selector = #selector(Branch.requestDeepLinkData(sceneOptions:scene:callback:))
        XCTAssertEqual(NSStringFromSelector(selector), "requestDeepLinkDataWithSceneOptions:scene:callback:")
        XCTAssertTrue(branch.responds(to: selector))
    }
    #endif

    // MARK: - NS_SWIFT_ASYNC_NAME: async variants

    /// `requestDeepLinkData:callback:` → `requestDeepLinkData(branchLink:) async throws`
    func testAsyncNameRequestDeepLinkDataBranchLink() {
        let method: (String?) async throws -> [AnyHashable: Any] =
            branch.requestDeepLinkData(branchLink:)
        _ = method
        XCTAssertTrue(branch.responds(to: NSSelectorFromString("requestDeepLinkData:callback:")))
    }

    /// `requestDeepLinkDataWithLaunchOptions:callback:` → `requestDeepLinkData(launchOptions:) async throws`
    func testAsyncNameRequestDeepLinkDataLaunchOptions() {
        let method: ([AnyHashable: Any]?) async throws -> [AnyHashable: Any] =
            branch.requestDeepLinkData(launchOptions:)
        _ = method
        XCTAssertTrue(branch.responds(to: NSSelectorFromString("requestDeepLinkDataWithLaunchOptions:callback:")))
    }

    #if !os(tvOS)
    /// `requestDeepLinkDataWithSceneOptions:scene:callback:` → `requestDeepLinkData(sceneOptions:scene:) async throws`
    func testAsyncNameRequestDeepLinkDataSceneOptionsScene() {
        let method: (UIScene.ConnectionOptions?, UIScene) async throws -> [AnyHashable: Any] =
            branch.requestDeepLinkData(sceneOptions:scene:)
        _ = method
        XCTAssertTrue(branch.responds(to: NSSelectorFromString("requestDeepLinkDataWithSceneOptions:scene:callback:")))
    }
    #endif

    /// `setUserAlias:completion:` → `setUserAlias(_:) async throws`
    ///
    /// The callback variant keeps its natural Swift name (`setUserAlias(_:completion:)`), so the
    /// two coexist as an async / non-async overload pair.
    func testAsyncNameSetUserAlias() {
        let asyncMethod: (String?) async throws -> [AnyHashable: Any] = branch.setUserAlias(_:)
        let callbackMethod: (String?, (([AnyHashable: Any]?, Error?) -> Void)?) -> Void =
            branch.setUserAlias(_:completion:)
        _ = asyncMethod
        _ = callbackMethod
        XCTAssertTrue(branch.responds(to: #selector(Branch.setUserAlias(_:completion:))))
    }

    /// `logoutWithCallback:` → `logoutAsync() async throws -> Bool`
    ///
    /// Deliberately *not* named `logout()`: that would shadow the fire-and-forget `logout` and
    /// force every existing async-context caller to add `try await`. This test pins both halves
    /// of that decision — the async name and the still-callable synchronous `logout()`.
    func testAsyncNameLogoutAsyncDoesNotShadowSynchronousLogout() {
        let asyncMethod: () async throws -> Bool = branch.logoutAsync
        let syncMethod: () -> Void = branch.logout
        _ = asyncMethod
        _ = syncMethod

        XCTAssertTrue(branch.responds(to: NSSelectorFromString("logoutWithCallback:")))
        XCTAssertTrue(branch.responds(to: #selector(Branch.logout)))
    }

    /// `lastAttributedTouchDataWithAttributionWindow:completion:` → `lastAttributedTouchData(attributionWindow:) async throws`
    func testAsyncNameLastAttributedTouchData() {
        let asyncMethod: (Int) async throws -> BranchLastAttributedTouchData =
            branch.lastAttributedTouchData(attributionWindow:)
        _ = asyncMethod
        XCTAssertTrue(branch.responds(to: NSSelectorFromString("lastAttributedTouchDataWithAttributionWindow:completion:")))
    }

    /// `getShortURLWithParams:andCallback:` → `getShortURL(params:) async throws -> String`
    func testAsyncNameGetShortURL() {
        let asyncMethod: ([AnyHashable: Any]?) async throws -> String = branch.getShortURL(params:)
        let callbackMethod: ([AnyHashable: Any]?, ((String?, Error?) -> Void)?) -> Void =
            branch.getShortURL(withParams:andCallback:)
        _ = asyncMethod
        _ = callbackMethod
        XCTAssertTrue(branch.responds(to: NSSelectorFromString("getShortURLWithParams:andCallback:")))
    }

    /// `BranchEvent.logEventWithCompletion:` → `logEventAsync() async throws -> Bool`
    ///
    /// Same reasoning as `logoutAsync()`: not named `logEvent()` so the fire-and-forget
    /// `logEvent` stays usable from an async context without `try await`.
    func testAsyncNameLogEventAsyncDoesNotShadowSynchronousLogEvent() {
        let event = BranchEvent.standardEvent(.viewItem)
        let asyncMethod: () async throws -> Bool = event.logEventAsync
        let syncMethod: () -> Void = event.logEvent
        _ = asyncMethod
        _ = syncMethod

        XCTAssertTrue(event.responds(to: NSSelectorFromString("logEventWithCompletion:")))
        XCTAssertTrue(event.responds(to: NSSelectorFromString("logEvent")))
    }

    // MARK: - Documented call sites

    /// Compile-only. Type-checks the call sites shown, commented out, in
    /// `SDKIntegrationTestApps/Source/iOSReleaseTest/AppDelegate.swift` and `SceneDelegate.swift`.
    ///
    /// The nested functions are never invoked, so no request is made; the value is entirely in the
    /// type check. They inherit this method's `@MainActor` isolation — the isolation a real app or
    /// scene delegate runs in — so a change to an imported signature breaks the build here instead
    /// of leaving behind an example that no longer compiles.
    ///
    /// Two deviations from those examples, both forced by this target's Swift 6 language mode. The
    /// integration app builds in Swift 5 mode, where the simpler forms shown there are accepted:
    ///
    /// - `Task.detached` rather than `Task { }`. The async variants return a non-Sendable
    ///   `[AnyHashable: Any]`, which an inherited main-actor task cannot receive: *"non-sendable
    ///   result type '[AnyHashable : Any]' cannot be sent from nonisolated context"*. A detached
    ///   task is nonisolated, so there is no actor to send the result back to.
    /// - The `launchOptions` variant is pinned in its callback form. Its
    ///   `[UIApplication.LaunchOptionsKey: Any]` argument is non-Sendable and belongs to the
    ///   main-actor region, so it cannot be captured into a detached task either — no async form of
    ///   it is expressible from a main-actor delegate under Swift 6.
    @MainActor
    func testDocumentedCallSitesTypeCheckFromMainActor() {
        // application(_:didFinishLaunchingWithOptions:) — callback form; see the note above.
        func didFinishLaunching(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
            Branch.sharedInstance().requestDeepLinkData(launchOptions: launchOptions) { params, error in
                _ = (params, error)
            }
        }

        // scene(_:continue:) and scene(_:openURLContexts:)
        func handleOpenedURL(_ url: URL) {
            Task.detached {
                _ = try? await Branch.sharedInstance().requestDeepLinkData(branchLink: url.absoluteString)
            }
        }

        _ = didFinishLaunching
        _ = handleOpenedURL

        #if !os(tvOS)
        // scene(_:willConnectTo:options:)
        func willConnect(scene: UIScene, connectionOptions: UIScene.ConnectionOptions) {
            Task.detached {
                _ = try? await Branch.sharedInstance().requestDeepLinkData(
                    sceneOptions: connectionOptions,
                    scene: scene
                )
            }
        }

        _ = willConnect
        #endif
    }

    // MARK: - Behavior through the renamed Swift entry points

    /// A URL-scheme cold start must not resolve through `launchOptions`: the URL-bearing call
    /// arrives separately via `application(_:open:options:)`, and enqueuing here as well would
    /// fire the callback twice for one app open. Network-free — the method returns early.
    @MainActor
    func testLaunchOptionsSkipsCallbackForURLSchemeColdStart() {
        let notCalled = expectation(description: "callback must not fire for a URL-scheme cold start")
        notCalled.isInverted = true

        branch.requestDeepLinkData(
            launchOptions: [UIApplication.LaunchOptionsKey.url: URL(string: "branchtest://open?id=1")!]
        ) { _, _ in
            notCalled.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    /// Same contract for a Universal Link cold start, where the URL arrives via
    /// `application(_:continue:restorationHandler:)`.
    @MainActor
    func testLaunchOptionsSkipsCallbackForUniversalLinkColdStart() {
        let notCalled = expectation(description: "callback must not fire for a Universal Link cold start")
        notCalled.isInverted = true

        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://bnctestbed.app.link/abcd1234")
        branch.requestDeepLinkData(
            launchOptions: [UIApplication.LaunchOptionsKey.userActivityDictionary: ["UIApplicationLaunchOptionsUserActivityKey": activity]]
        ) { _, _ in
            notCalled.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }
}
