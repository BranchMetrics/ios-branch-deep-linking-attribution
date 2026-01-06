//
//  Config.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import ProjectDescription

let config = Config(
    compatibleXcodeVersions: .upToNextMajor("16.0"),
    swiftVersion: "6.0",
    generationOptions: .options(
        resolveDependenciesWithSystemScm: false,
        disablePackageVersionLocking: false,
        clonedSourcePackagesDirPath: nil,
        staticSideEffectsWarningTargets: .all,
        enforceExplicitDependencies: true,
        defaultConfiguration: "Debug"
    )
)
