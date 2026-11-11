//
//  MultiSceneWireValidationTests.swift
//  iOSReleaseTestUITests
//
//  Multi-scene L1 captures. Each class is one capture, since the app deletes branchlogs.txt on
//  launch. All need a device that supports multiple scenes (iPad); run them with
//  REQUIRE_MULTI_SCENE=1 so scripts/run_l1_instrumented.sh refuses an iPhone.
//
//  Scene callbacks are written to branchlogs.txt as `[SceneCallback] scene=<name> params=<json>`;
//  scripts/check_scene_routing.py asserts which scene received each result.
//

import XCTest

/// multiscene_open: cold launch with no link, then Scene 2 opens with nil options.
final class MultiSceneOpenWireTest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSecondSceneOpenEmitsWirePayload() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTest", "1"]
        launchAndWait(app)
        settle(seconds: 8)
        openSecondScene(app)
        settle(seconds: 8)
    }
}

/// multiscene_link_scene2: a link delivered to Scene 2 while Scene 1 is connected.
final class MultiSceneLinkToScene2WireTest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLinkToSecondSceneRoutesToSecondScene() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTest", "1", "-testSceneLinkURL", L1Fixture.link, "-testSceneLinkTarget", "scene2"]
        launchAndWait(app)
        settle(seconds: 8)
        openSecondScene(app)
        settle(seconds: 12)
    }
}

/// multiscene_link_scene1: a link delivered to Scene 1 while Scene 2 is connected.
final class MultiSceneLinkToScene1WireTest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLinkToFirstSceneRoutesToFirstScene() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTest", "1", "-testSceneLinkURL", L1Fixture.link, "-testSceneLinkTarget", "scene1"]
        launchAndWait(app)
        settle(seconds: 8)
        openSecondScene(app)
        settle(seconds: 12)
    }
}

/// multiscene_foreground: background and foreground the app with two scenes connected.
final class MultiSceneForegroundWireTest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testForegroundWithTwoScenesSendsOpenWithoutCallback() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTest", "1"]
        launchAndWait(app)
        settle(seconds: 8)
        openSecondScene(app)
        settle(seconds: 8)

        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 15), "iOSReleaseTest did not reach the background")
        settle(seconds: 3)

        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "iOSReleaseTest did not return to the foreground")
        settle(seconds: 8)
    }
}
