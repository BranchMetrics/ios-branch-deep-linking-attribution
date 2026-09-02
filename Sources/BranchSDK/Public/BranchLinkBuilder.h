//
//  BranchLinkBuilder.h
//  BranchSDK
//
//  Created by Brandon Boothe on 8/31/26.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#import "BNCCallbacks.h"
#import "BNCLinkData.h"

NS_ASSUME_NONNULL_BEGIN

/**
 `BranchLinkBuilder` collects every link-generation option into a single object, replacing the 36
 telescoping `getShortURL…` / `getLongURL…` / `getSpotlightUrl…` overloads that used to live on
 `Branch`.

 This class is a plain mutable builder: create it, set the properties you care about, then call a
 terminal. It follows the same shape as `BranchConfiguration` — construct, assign, hand off — so
 there is one pattern to learn across the 4.0 surface.

     BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];
     builder.params = @{@"$og_title": @"Sale"};
     builder.channel = @"sms";
     builder.feature = @"share";

     [builder fetchShortURLWithCallback:^(NSString *url, NSError *error) {
         // Check `error`, not `url` — see "Choosing a terminal" below.
         if (error) return;
         // `url` is a short Branch link. This callback runs on the main queue.
     }];

 A builder is reusable: the terminals do not mutate it, so you can change a property and call
 another terminal.

 ## Choosing a terminal

 The verb tells you whether the call touches the network:

 - `-buildLongURL` — **offline**, returns immediately. The link's data is encoded into the URL, so
   it works with no connectivity, but the URL is long.
 - `-fetchShortURLWithCallback:` — **network**, non-blocking. Prefer this. The callback is delivered
   on the main queue.
 - `-fetchShortURL` — **network**, blocking. Never call it on the main thread; it freezes the UI for
   a full network round trip, or for the request timeout on a bad connection.
 - `-fetchSpotlightURLWithCallback:` — **network**, for Core Spotlight indexing. Reads `params` only.

 On a server error the two short-URL terminals hand back a **long-link fallback**, not nil — so a
 non-nil URL is not proof of success. Check `error`.

 ## Migrating from the `Branch` link methods (4.0 breaking change)

 Every method below was removed. Set the corresponding properties, then call a terminal. Options you
 do not set are simply omitted, so the short forms of the old overloads map to setting less.

 | Removed on `Branch`                                     | Replacement                                               |
 | ------------------------------------------------------- | --------------------------------------------------------- |
 | `getShortURL`, `getShortURLWithParams:…`                 | set the options, then `-fetchShortURL`                      |
 | `getShortUrlWithParams:…andCampaign:andMatchDuration:`   | also set `campaign` / `matchDuration`                       |
 | `getShortURLWithParams:…ignoreUAString:forceLinkCreation:` | also set `ignoreUAString` (see below re `forceLinkCreation`) |
 | `getShortURLWithParams:…andCallback:` (all async forms)  | `-fetchShortURLWithCallback:`                               |
 | `getLongURLWithParams:…`                                 | `-buildLongURL`                                             |
 | `getLongAppLinkURLWithParams:…`                          | set `useAppLinkDomain = YES`, then `-buildLongURL`          |
 | `getSpotlightUrlWithParams:callback:`                    | set `params`, then `-fetchSpotlightURLWithCallback:`        |

 Argument renames: `andType:` → `linkType`, `andMatchDuration:` → `matchDuration`, `andTags:` →
 `tags`, and so on for each `and…:` keyword.

 Three behavior changes to be aware of:

 1. **`forceLinkCreation:` is gone.** It was accepted and never read, so passing it changed nothing.
 2. **Long URLs now include `channel`.** `getLongURLWithParams:andChannel:…` and
    `getLongAppLinkURLWithParams:andChannel:…` accepted a channel and then dropped it before
    assembling the URL. That was a bug. `-buildLongURL` emits `channel=`, so a long link built with
    a channel set is not byte-identical to what 3.x produced.
 3. **There is no `Branch`-instance entry point.** Construct a builder directly; you do not need a
    `Branch` reference to make a link.

 Unlike `BranchConfiguration`, there is no `-validate:`. A configuration is read once at launch, so
 a bad one is a programming error worth surfacing as an `NSError`. Link generation happens at
 runtime in response to user action, so the terminals instead log through `BranchLogger` and return
 nil (or call back with an error).
 */
@interface BranchLinkBuilder : NSObject

#pragma mark - Link content

/// Link parameters. Base64-encoded into long URLs; sent as the link's data on short-link requests.
/// Branch-reserved keys (`$og_title`, `$desktop_url`, …) control link behavior; anything else is
/// passed through to your app.
@property (nonatomic, copy, nullable) NSDictionary *params;

/// Free-form tags used to organize links in the Branch dashboard.
@property (nonatomic, copy, nullable) NSArray<NSString *> *tags;

/// A vanity path for the link, e.g. `@"summer-sale"` for `https://example.app.link/summer-sale`.
/// Aliases are globally unique per domain; reusing one returns the existing link.
@property (nonatomic, copy, nullable) NSString *alias;

/// The medium the link is shared through, e.g. `@"sms"` or `@"facebook"`.
@property (nonatomic, copy, nullable) NSString *channel;

/// The feature the link supports, e.g. `@"share"` or `@"invite"`.
@property (nonatomic, copy, nullable) NSString *feature;

/// Where in your funnel the link was created, e.g. `@"level_2"`.
@property (nonatomic, copy, nullable) NSString *stage;

/// The marketing campaign the link belongs to.
///
/// Short-link terminals only. `-buildLongURL` never emits a campaign, matching the behavior of the
/// `getLongURL…` methods this builder replaces.
@property (nonatomic, copy, nullable) NSString *campaign;

#pragma mark - Link behavior

/// How long, in seconds, the Branch backend should consider a click eligible to match an install.
/// Default 0, which means "use the Branch default" and emits no `matchDuration` on long URLs.
@property (nonatomic, assign) NSUInteger matchDuration;

/// Whether the link may be clicked once or without limit. Default `BranchLinkTypeUnlimitedUse`.
///
/// `BranchLinkTypeUnlimitedUse` is 0, so a default builder emits no `type` on long URLs.
@property (nonatomic, assign) BranchLinkType linkType;

#pragma mark - Terminal-specific options

/// A User-Agent string the Branch backend should ignore, so a link preview scrape is not counted as
/// a click.
///
/// Applies to `-fetchShortURL` only, where it also bypasses the link-cache read so the call always
/// reaches the network. Setting it and then calling any other terminal logs a warning and is
/// otherwise ignored.
///
/// It is sent as link data but is **not** part of the cache key, so the fetched link is stored under
/// the same key an otherwise-identical link would use — a later call without an `ignoreUAString` may
/// be served this link from the cache.
@property (nonatomic, copy, nullable) NSString *ignoreUAString;

/// When YES, `-buildLongURL` builds against your app.link domain instead of the default link
/// domain. Default NO.
///
/// Applies to `-buildLongURL` only; setting it and then calling a short-URL or spotlight terminal
/// logs a warning and is otherwise ignored.
@property (nonatomic, assign) BOOL useAppLinkDomain;

#pragma mark - Initialization

- (instancetype)init;

#pragma mark - Terminals

// "build" is offline and synchronous; "fetch" reaches the Branch servers. The verb keeps that
// distinction visible at the call site rather than hiding it behind a uniform name.

/**
 Requests a short Branch link, **blocking the calling thread** until the server responds.

 Do not call this on the main thread. It performs a synchronous network round trip, so on the main
 thread it freezes the UI for the duration and, on a slow or unreachable network, for the full
 request timeout.

 Results are cached: a second call with identical link options returns the cached URL without a
 request. Setting `ignoreUAString` bypasses that cache read, so the call always reaches the network.

 If the server returns a non-200, the SDK falls back to a long link built from the last known link
 domain — so a non-nil result is not proof the request succeeded. When no link domain is known yet,
 the fallback returns nil.

 Reads every link-content property plus `campaign`, `matchDuration`, `linkType` and
 `ignoreUAString`. `useAppLinkDomain` does not apply and is ignored with a warning.

 @return The short URL; a long-URL fallback on a server error; or nil.
 */
- (nullable NSString *)fetchShortURL;

/**
 Requests a short Branch link without blocking, delivering it to `callback`.

 Prefer this over `-fetchShortURL` everywhere, and especially on the main thread.

 The callback is invoked on the **main queue**, so it is safe to update UI from it directly. On a
 server error the callback receives a long-link fallback together with the error, rather than a nil
 URL — check `error`, not the URL, to decide whether the request succeeded.

 Results share the same cache as `-fetchShortURL`: a second call with identical link options calls
 back with the cached URL and issues no request.

 Reads every link-content property plus `campaign`, `matchDuration` and `linkType`.
 `ignoreUAString` and `useAppLinkDomain` do not apply and are ignored with a warning.

 @param callback Receives the short URL, or a long-link fallback plus an error. May be nil, in which
        case the link is still created and cached.
 */
- (void)fetchShortURLWithCallback:(nullable callbackWithUrl)callback;

/**
 Builds a long Branch link offline, with no network call.

 The link's `params` are JSON-encoded and base64'd into the URL's `data` query item, so the whole
 link is self-describing and can be produced with no connectivity and no round trip. That also
 makes it long — prefer a short link where the URL is user-visible.

 Reads `params`, `tags`, `alias`, `channel`, `feature`, `stage`, `linkType`, `matchDuration` and
 `useAppLinkDomain`. A long URL has no campaign parameter, so `campaign` is silently unused;
 `ignoreUAString` does not apply either and is ignored with a warning.

 @return The long URL, or nil if the Branch key is unavailable.
 */
- (nullable NSString *)buildLongURL;

/**
 Requests the Branch link used to attribute a Core Spotlight index entry, delivering the server's
 response to `callback`.

 This is the terminal behind Spotlight indexing. Unlike the other short-link terminals it calls back
 with the server's whole link payload rather than just a URL, because Core Spotlight needs the
 accompanying fields — the URL alone is under the `url` key.

 A Spotlight link is not an ordinary link, and the SDK fixes its shape: the only builder property
 read is `params`. The link is always created with a channel of `spotlight`; `tags`, `alias`,
 `channel`, `feature`, `stage`, `campaign`, `linkType` and `matchDuration` are ignored, and setting
 any of them logs a warning. `ignoreUAString` and `useAppLinkDomain` do not apply either.

 Results are **not** cached — every call reaches the network, where the two `fetchShortURL…`
 terminals share a link cache.

 The callback is invoked on the **main thread**. On a server error it receives an empty dictionary
 together with the error, rather than nil.

 @param callback Receives the server's link payload, or an empty dictionary plus an error. May be
        nil, in which case the link is still created.
 */
- (void)fetchSpotlightURLWithCallback:(nullable callbackWithParams)callback;

@end

NS_ASSUME_NONNULL_END
