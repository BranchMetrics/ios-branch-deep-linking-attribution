//
//  BranchSDK.swift
//  BranchSDK umbrella
//
//  SwiftPM cannot put the SDK in one mixed-language target, so it is physically split into three
//  modules (BranchCore + BranchSwiftSDK + BranchObjCSDK). This thin Swift target re-exports all three
//  so that a SwiftPM consumer only has to write `import BranchSDK` and still sees `Branch`,
//  `BranchConfiguration`, `BranchAttributionLevel`, and everything else — matching the single-module
//  experience that CocoaPods / Carthage / the xcframework already provide.
//

@_exported import BranchCore
@_exported import BranchSwiftSDK
@_exported import BranchObjCSDK
