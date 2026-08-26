//
//  BranchInterfaceTests.swift
//  BranchSDKTests
//
//  Created by Brandon Boothe on 8/4/26.
//

import XCTest
import UIKit
import BranchSDK

// MARK: - Test double

/// A network-free stand-in for `Branch` used to prove the protocol is mockable.
/// Records the calls a consumer makes and returns caller-supplied stub values.
private final class FakeBranch: NSObject, BranchInterface {

    let stubbedLatestParams: [AnyHashable: Any]?
    let stubbedFirstParams: [AnyHashable: Any]?

    private(set) var sendOpenCallCount = 0
    private(set) var logoutCallCount = 0
    private(set) var lastUserAlias: String?
    private(set) var lastAttributionLevel: BranchAttributionLevel?

    init(latestParams: [AnyHashable: Any]? = nil,
         firstParams: [AnyHashable: Any]? = nil) {
        self.stubbedLatestParams = latestParams
        self.stubbedFirstParams = firstParams
    }

    func requestDeepLinkData(branchLink: String?, callback: callbackWithParams? = nil) {
        callback?(stubbedLatestParams, nil)
    }

    func requestDeepLinkData(launchOptions options: [AnyHashable: Any]?, callback: callbackWithParams? = nil) {
        callback?(stubbedLatestParams, nil)
    }

    func requestDeepLinkData(openURL url: URL?) {}

    func requestDeepLinkData(openURL url: URL?, sourceApplication: String?, annotation: Any?) {}

    func requestDeepLinkData(userActivity: NSUserActivity?) {}

    func requestDeepLinkData(userInfo: [AnyHashable: Any]?) {}

    @available(iOS 13.0, macCatalyst 13.1, *)
    func requestDeepLinkData(sceneOptions connectionOptions: UIScene.ConnectionOptions?,
                             scene: UIScene,
                             callback: callbackWithParams? = nil) {
        callback?(stubbedLatestParams, nil)
    }

    @available(iOS 13.0, *)
    func requestDeepLinkData(scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {}

    @available(iOS 13.0, *)
    func requestDeepLinkData(scene: UIScene, userActivity: NSUserActivity) {}

    func sendOpen() {
        sendOpenCallCount += 1
    }

    func getLatestReferringParams() -> [AnyHashable: Any]? {
        stubbedLatestParams
    }

    func getFirstReferringParams() -> [AnyHashable: Any]? {
        stubbedFirstParams
    }

    func setUserAlias(_ userAlias: String?, completion: callbackWithParams? = nil) {
        lastUserAlias = userAlias
        completion?(stubbedLatestParams, nil)
    }

    func logout() {
        logoutCallCount += 1
    }

    func logout(callback: callbackWithStatus? = nil) {
        logoutCallCount += 1
        callback?(true, nil)
    }

    func setConsumerProtectionAttributionLevel(_ level: BranchAttributionLevel) {
        lastAttributionLevel = level
    }

    func addFacebookPartnerParameter(withName name: String, value: String) {}
    func addSnapPartnerParameter(withName name: String, value: String) {}
    func clearPartnerParameters() {}
}

// MARK: - Consumer under test

/// A tiny production-shaped type that depends only on the protocol, exactly as the spec envisions.
private final class DeepLinkHandler {
    private let branch: BranchInterface
    init(branch: BranchInterface) {
        self.branch = branch
    }

    /// Returns the value of the `screen` key from the latest referring params.
    func currentScreen() -> String? {
        branch.getLatestReferringParams()?["screen"] as? String
    }
}

// MARK: - Tests

final class BranchInterfaceTests: XCTestCase {

    /// A mock conforming to `BranchInterface` can be injected and drives consumer behavior.
    func testMockIsInjectableIntoConsumer() {
        let fake = FakeBranch(latestParams: ["screen": "home"])
        let handler = DeepLinkHandler(branch: fake)
        XCTAssertEqual(handler.currentScreen(), "home",
                       "Consumer should read stubbed params from the injected mock")
    }

    /// Calls made through the protocol reach the mock and are recorded.
    func testProtocolCallsReachMock() {
        let fake = FakeBranch()
        let branch: BranchInterface = fake

        branch.sendOpen()
        branch.setUserAlias("emt4013-user", completion: nil)
        branch.setConsumerProtectionAttributionLevel(.full)
        branch.logout()

        XCTAssertEqual(fake.sendOpenCallCount, 1)
        XCTAssertEqual(fake.lastUserAlias, "emt4013-user")
        XCTAssertEqual(fake.lastAttributionLevel, .full)
        XCTAssertEqual(fake.logoutCallCount, 1)
    }

    /// `getFirstReferringParams` and `getLatestReferringParams` are independently stubbable.
    func testReferringParamsAreDistinct() {
        let fake = FakeBranch(latestParams: ["screen": "latest"],
                              firstParams: ["screen": "first"])
        let branch: BranchInterface = fake
        XCTAssertEqual(branch.getLatestReferringParams()?["screen"] as? String, "latest")
        XCTAssertEqual(branch.getFirstReferringParams()?["screen"] as? String, "first")
    }

    /// Compile-time proof that the real `Branch` singleton conforms to `BranchInterface`.
    /// If any protocol method were removed from `Branch`, this assignment would fail to build.
    func testBranchConformsToBranchInterface() {
        let resetSelector = NSSelectorFromString("resetInitializationGuardForTesting")
        if (Branch.self as AnyObject).responds(to: resetSelector) {
            _ = (Branch.self as AnyObject).perform(resetSelector)
        }
        let config = BranchConfiguration(key: "key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB")
        let branch: BranchInterface = Branch.initialize(config)
        XCTAssertNotNil(branch, "Branch.initialize should return a BranchInterface-conforming instance")
    }
}
