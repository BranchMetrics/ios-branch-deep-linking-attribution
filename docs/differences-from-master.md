# What is different from `master` (3.x)

Read this before porting anything across the two lines.

1. **The queue is an `NSOperationQueue`.** `processNextQueueItem` is gone from `Sources/`. Each
   request is wrapped in a `BNCServerRequestOperation` that the queue executes, so execution
   lives in the operation, not in `Branch.m`.
2. **The open and event endpoints moved to `/v3`**, and a deep-link resolution endpoint is new.
   Verified against `Sources/BranchSDK/BNCServerAPI.m` on both lines:

   | Accessor | `master` | this line |
   | --- | --- | --- |
   | `installServiceURL` | `/v1/install` | `/v1/install` |
   | `openServiceURL` | `/v1/open` | `/v3/events/open` |
   | `deepLinkServiceURL` | does not exist | `/v3/deeplink` |
   | `standardEventServiceURL` | `/v2/event/standard` | `/v3/events/standard` |
   | `customEventServiceURL` | `/v2/event/custom` | `/v3/events/custom` |
   | `linkServiceURL`, `qrcodeServiceURL`, `latdServiceURL`, `validationServiceURL` | unchanged | unchanged |
3. **New public deep-link API.** The `initSession…` family is **removed**. `+[Branch initialize:]`
   with a `BranchConfiguration` is the entry point, and `requestDeepLinkData:callback:` and its
   siblings replace driving everything through the old session-init calls.
4. **`+setTrackingDisabled:` and `+trackingDisabled` are removed** from the public header and
   from `Branch.m`. Attribution gating is `setConsumerProtectionAttributionLevel:` plus
   `+attributionLevelNone`. Code referencing `Branch.trackingDisabled` will not compile here.
5. **No init status and no session ID.** `BNCInitStatus` and `sessionID` do not exist in
   `Sources/`. Session identity is `randomizedBundleToken` plus `randomizedDeviceToken`, which
   are per install and per device, not per foreground.
6. **No fastlane.** Tests run directly through `xcodebuild` against a first-class
   `BranchSDKTests/` target.
7. **Minimum iOS is 15.0, not 12.0.** Raised for Xcode 27, which rejects a deployment target
   below 15.0 for both simulator and device (`master` still targets 12.0). tvOS is 15.0 too, the
   same Xcode 27 floor. `BranchSDK.xcodeproj`, `Package.swift`, `BranchSDK.podspec`.
8. **The scene callback is `callbackWithParamsAndScene`.** On `master`, `BranchScene`'s
   `initSessionWithLaunchOptions:registerDeepLinkHandler:` passed `(params, error, scene)`,
   resolving the scene from `BNCInitSessionResponse.sceneIdentifier`. Both are gone here.
   `requestDeepLinkDataWithSceneOptions:scene:callback:` on `Branch` takes the same three-argument
   shape. Each scene entry point captures `scene.session.persistentIdentifier` in that request's
   completion block, and the scene is looked up in `connectedScenes` on delivery. Nothing about the
   scene is carried on the request or through the queue. The callback is stored per scene, keyed by
   the same persistent identifier, so several windows each keep their own; `master` held one
   handler. The latest non-nil callback also takes results with no scene callback.
9. **`BranchScene` is removed.** `master` routes `scene:continueUserActivity:` and
   `scene:openURLContexts:` through `BranchScene.shared`. Here they are
   `requestDeepLinkDataWithScene:continueUserActivity:` and
   `requestDeepLinkDataWithScene:openURLContexts:` on `Branch`, available on iOS and tvOS. The
   scene-connect method stays iOS-only.

## How the session state came out

Useful when a stack trace or a blame lands on code that no longer looks like `master`. The rest
of these docs describe the post-merge shape.

- **#1570** removed `initSafetyCheck`.
- **#1603** removed the initialization states and `sessionID`.
- **#1605** added AppDelegate convenience methods wrapping `requestDeepLinkData`
  (`requestDeepLinkDataWithURL:`, `…WithUserActivity:`), replacing direct `continueUserActivity:`
  and `handlePushNotification:` use.
- **#1614** added `BranchConfiguration` plus `+[Branch initialize:]`, superseding the public API
  setters. `BranchConfiguration.m` sits alongside the existing `BranchConfigurationController.m`.
