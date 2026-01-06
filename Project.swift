//
//  Project.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import ProjectDescription

// MARK: - Project Configuration

let projectName = "BranchSDK"
let organizationName = "Branch Metrics"
let bundleIdPrefix = "io.branch"

// MARK: - Build Settings

let baseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6.0",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "DEAD_CODE_STRIPPING": "YES",
    "CODE_SIGN_IDENTITY": "",
    "CODE_SIGNING_REQUIRED": "NO",
    "DEVELOPMENT_TEAM": "",
]

let debugSettings: SettingsDictionary = [
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
    "ENABLE_TESTABILITY": "YES",
    "GCC_PREPROCESSOR_DEFINITIONS": "DEBUG=1 $(inherited)",
]

let releaseSettings: SettingsDictionary = [
    "SWIFT_OPTIMIZATION_LEVEL": "-O",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "GCC_PREPROCESSOR_DEFINITIONS": "$(inherited)",
    "SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES",
]

// MARK: - Deployment Targets

let deploymentTargets = DeploymentTargets.multiplatform(
    iOS: "15.0",
    macOS: "12.0",
    watchOS: "8.0",
    tvOS: "15.0",
    visionOS: "1.0"
)

/// Test targets only run on iOS/macOS
let testDeploymentTargets = DeploymentTargets.multiplatform(
    iOS: "15.0",
    macOS: "12.0"
)

// MARK: - Targets

let branchSDKTarget = Target.target(
    name: "BranchSDK",
    destinations: [.iPhone, .iPad, .mac, .appleWatch, .appleTv, .appleVision],
    product: .framework,
    bundleId: "\(bundleIdPrefix).sdk",
    deploymentTargets: deploymentTargets,
    infoPlist: .extendingDefault(with: [
        "CFBundleShortVersionString": "4.0.0",
        "CFBundleVersion": "1",
        "NSPrivacyTracking": false,
        "NSPrivacyTrackingDomains": [],
        "NSPrivacyCollectedDataTypes": [],
        "NSPrivacyAccessedAPITypes": [
            [
                "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
                "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
            ],
            [
                "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategorySystemBootTime",
                "NSPrivacyAccessedAPITypeReasons": ["35F9.1"],
            ],
        ],
    ]),
    sources: ["Sources/BranchSDK/**"],
    resources: [],
    dependencies: [],
    settings: .settings(
        base: baseSettings,
        configurations: [
            .debug(name: "Debug", settings: debugSettings),
            .release(name: "Release", settings: releaseSettings),
        ]
    )
)

let branchSDKTestKitTarget = Target.target(
    name: "BranchSDKTestKit",
    destinations: [.iPhone, .iPad, .mac, .appleWatch, .appleTv, .appleVision],
    product: .framework,
    bundleId: "\(bundleIdPrefix).sdk.testkit",
    deploymentTargets: deploymentTargets,
    sources: ["Sources/BranchSDKTestKit/**"],
    dependencies: [
        .target(name: "BranchSDK"),
    ],
    settings: .settings(
        base: baseSettings,
        configurations: [
            .debug(name: "Debug", settings: debugSettings),
            .release(name: "Release", settings: releaseSettings),
        ]
    )
)

let branchSDKTestsTarget = Target.target(
    name: "BranchSDKTests",
    destinations: [.iPhone, .iPad, .mac],
    product: .unitTests,
    bundleId: "\(bundleIdPrefix).sdk.tests",
    deploymentTargets: testDeploymentTargets,
    sources: ["Tests/BranchSDKTests/**"],
    dependencies: [
        .target(name: "BranchSDK"),
        .target(name: "BranchSDKTestKit"),
    ],
    settings: .settings(
        base: baseSettings.merging([
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG TESTING",
        ]),
        configurations: [
            .debug(name: "Debug", settings: debugSettings),
            .release(name: "Release", settings: releaseSettings),
        ]
    )
)

let integrationTestsTarget = Target.target(
    name: "BranchSDKIntegrationTests",
    destinations: [.iPhone, .iPad, .mac],
    product: .unitTests,
    bundleId: "\(bundleIdPrefix).sdk.integration-tests",
    deploymentTargets: testDeploymentTargets,
    sources: ["Tests/BranchSDKIntegrationTests/**"],
    dependencies: [
        .target(name: "BranchSDK"),
        .target(name: "BranchSDKTestKit"),
    ],
    settings: .settings(
        base: baseSettings.merging([
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG INTEGRATION_TESTING",
        ]),
        configurations: [
            .debug(name: "Debug", settings: debugSettings),
            .release(name: "Release", settings: releaseSettings),
        ]
    )
)

let performanceTestsTarget = Target.target(
    name: "BranchSDKPerformanceTests",
    destinations: [.iPhone, .iPad, .mac],
    product: .unitTests,
    bundleId: "\(bundleIdPrefix).sdk.performance-tests",
    deploymentTargets: testDeploymentTargets,
    sources: ["Tests/BranchSDKPerformanceTests/**"],
    dependencies: [
        .target(name: "BranchSDK"),
    ],
    settings: .settings(
        base: baseSettings.merging([
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG PERFORMANCE_TESTING",
        ]),
        configurations: [
            .debug(name: "Debug", settings: debugSettings),
            .release(name: "Release", settings: releaseSettings),
        ]
    )
)

// MARK: - Schemes

let schemes: [Scheme] = [
    .scheme(
        name: "BranchSDK",
        shared: true,
        buildAction: .buildAction(
            targets: ["BranchSDK"],
            preActions: [],
            postActions: []
        ),
        testAction: .targets(
            ["BranchSDKTests"],
            configuration: "Debug",
            options: .options(coverage: true, codeCoverageTargets: ["BranchSDK"])
        ),
        runAction: .runAction(configuration: "Debug"),
        archiveAction: .archiveAction(configuration: "Release"),
        profileAction: .profileAction(configuration: "Release"),
        analyzeAction: .analyzeAction(configuration: "Debug")
    ),
    .scheme(
        name: "BranchSDK-All-Tests",
        shared: true,
        buildAction: .buildAction(
            targets: ["BranchSDK", "BranchSDKTestKit"]
        ),
        testAction: .targets(
            [
                "BranchSDKTests",
                "BranchSDKIntegrationTests",
                "BranchSDKPerformanceTests",
            ],
            configuration: "Debug",
            options: .options(coverage: true, codeCoverageTargets: ["BranchSDK"])
        )
    ),
]

// MARK: - Project

let project = Project(
    name: projectName,
    organizationName: organizationName,
    options: .options(
        automaticSchemesOptions: .disabled,
        textSettings: .textSettings(
            usesTabs: false,
            indentWidth: 4,
            tabWidth: 4,
            wrapsLines: true
        )
    ),
    packages: [],
    settings: .settings(
        base: baseSettings,
        configurations: [
            .debug(name: "Debug", settings: debugSettings),
            .release(name: "Release", settings: releaseSettings),
        ]
    ),
    targets: [
        branchSDKTarget,
        branchSDKTestKitTarget,
        branchSDKTestsTarget,
        integrationTestsTarget,
        performanceTestsTarget,
    ],
    schemes: schemes,
    additionalFiles: [
        .glob(pattern: "README.md"),
        .glob(pattern: "CHANGELOG.md"),
        .glob(pattern: "LICENSE"),
        .glob(pattern: ".swiftlint.yml"),
        .glob(pattern: ".swiftformat"),
    ]
)
