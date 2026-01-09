//
//  Session+Legacy.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - LegacySessionKeys

/// Constants for legacy session dictionary keys.
///
/// These keys match the v3 SDK constants defined in `Branch.h` for
/// backward compatibility with existing integrations.
public enum LegacySessionKeys {
    /// The channel on which the link was shared
    public static let channel = "+channel"

    /// The feature (e.g., "invite", "share")
    public static let feature = "+feature"

    /// Tags associated with the link
    public static let tags = "+tags"

    /// The campaign associated with the link
    public static let campaign = "+campaign"

    /// The stage in the user journey
    public static let stage = "+stage"

    /// Where the link was created
    public static let creationSource = "+creation_source"

    /// The referrer for the link click
    public static let referrer = "+referrer"

    /// The phone number (if user texted themselves)
    public static let phoneNumber = "+phone_number"

    /// Whether this is the first session (install)
    public static let isFirstSession = "+is_first_session"

    /// Whether a Branch link was clicked
    public static let clickedBranchLink = "+clicked_branch_link"

    /// The referring link URL
    public static let referringLink = "~referring_link"

    /// Match guarantee flag
    public static let matchGuaranteed = "+match_guaranteed"

    /// Click timestamp
    public static let clickTimestamp = "+click_timestamp"

    /// URL string
    public static let url = "+url"
}

// MARK: - Session Legacy Extensions

public extension Session {
    /// Converts the session to a dictionary suitable for legacy callbacks.
    ///
    /// This dictionary format matches the v3 SDK's callback format,
    /// ensuring backward compatibility with existing integrations.
    ///
    /// ## Keys Included
    ///
    /// - `+is_first_session`: Whether this is an install
    /// - `+clicked_branch_link`: Whether a Branch link was clicked
    /// - Link data parameters (if present)
    ///
    /// - Returns: Dictionary representation for legacy callbacks
    var legacyDictionary: [String: Any] {
        var dict: [String: Any] = [:]

        // Add session metadata
        dict[LegacySessionKeys.isFirstSession] = isFirstSession

        // Add link data if present
        if let linkData {
            dict[LegacySessionKeys.clickedBranchLink] = linkData.isClicked

            // Add link metadata
            if let channel = linkData.channel {
                dict[LegacySessionKeys.channel] = channel
            }
            if let feature = linkData.feature {
                dict[LegacySessionKeys.feature] = feature
            }
            if let campaign = linkData.campaign {
                dict[LegacySessionKeys.campaign] = campaign
            }
            if let stage = linkData.stage {
                dict[LegacySessionKeys.stage] = stage
            }
            if let tags = linkData.tags, !tags.isEmpty {
                dict[LegacySessionKeys.tags] = tags
            }
            if let referringLink = linkData.referringLink {
                dict[LegacySessionKeys.referringLink] = referringLink
            }
            if let url = linkData.url {
                dict[LegacySessionKeys.url] = url.absoluteString
            }

            // Add custom parameters
            for (key, value) in linkData.parameters {
                dict[key] = value.value
            }

            // Add raw data (server response)
            for (key, value) in linkData.rawData {
                // Don't override already set keys
                if dict[key] == nil {
                    dict[key] = value.value
                }
            }
        } else {
            dict[LegacySessionKeys.clickedBranchLink] = false
        }

        return dict
    }

    /// Converts the session to an NSDictionary for Objective-C compatibility.
    ///
    /// - Returns: NSDictionary representation for legacy Obj-C callbacks
    var legacyNSDictionary: NSDictionary {
        legacyDictionary as NSDictionary
    }
}

// MARK: - LinkData Legacy Extensions

public extension LinkData {
    /// Converts the link data to a dictionary for legacy callbacks.
    ///
    /// - Returns: Dictionary representation of link data
    var legacyDictionary: [String: Any] {
        var dict: [String: Any] = [:]

        dict[LegacySessionKeys.clickedBranchLink] = isClicked

        if let channel {
            dict[LegacySessionKeys.channel] = channel
        }
        if let feature {
            dict[LegacySessionKeys.feature] = feature
        }
        if let campaign {
            dict[LegacySessionKeys.campaign] = campaign
        }
        if let stage {
            dict[LegacySessionKeys.stage] = stage
        }
        if let tags, !tags.isEmpty {
            dict[LegacySessionKeys.tags] = tags
        }
        if let referringLink {
            dict[LegacySessionKeys.referringLink] = referringLink
        }
        if let url {
            dict[LegacySessionKeys.url] = url.absoluteString
        }

        // Add custom parameters
        for (key, value) in parameters {
            dict[key] = value.value
        }

        // Add raw data
        for (key, value) in rawData {
            if dict[key] == nil {
                dict[key] = value.value
            }
        }

        return dict
    }

    /// Converts to NSDictionary for Objective-C compatibility.
    var legacyNSDictionary: NSDictionary {
        legacyDictionary as NSDictionary
    }
}
