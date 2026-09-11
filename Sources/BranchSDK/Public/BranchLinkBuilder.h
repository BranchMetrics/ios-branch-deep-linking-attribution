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
#import "BranchLinkProperties.h"

NS_ASSUME_NONNULL_BEGIN

/**
 `BranchLinkBuilder` generates Branch links.

 The link's content and behavior — tags, alias, channel, feature, stage, campaign, match duration
 and link type — are carried by a `BranchLinkProperties`, which each terminal takes as an argument.
 The builder itself holds only `params`, the link's data payload.

     BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
     linkProperties.channel = @"sms";
     linkProperties.feature = @"share";

     BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];
     builder.params = @{@"$og_title": @"Sale"};

     [builder getShortURLWithParamsWithLinkProperties:linkProperties
                                            callback:^(NSString *url, NSError *error) {
         // Check `error`, not `url` — see "Choosing a terminal" below.
         if (error) return;
         // `url` is a short Branch link. This callback runs on the main queue.
     }];

 A builder is reusable: the terminals do not mutate it or the link properties handed to them, so the
 same builder can generate several links.

 ## Choosing a terminal

 The verb tells you whether the call touches the network:

 - `-getLongURLWithLinkProperties:useAppLinkDomain:` — **offline**, returns immediately. The link's
   data is encoded into the URL, so it works with no connectivity, but the URL is long.
 - `-getShortURLWithParamsWithLinkProperties:callback:` — **network**, non-blocking. Prefer this. The
   callback is delivered on the main queue.
 - `-getShortURLWithLinkProperties:` and `-getShortURLWithLinkProperties:ignoreUAString:` —
   **network**, blocking. Never call them on the main thread; they freeze the UI for a full network
   round trip, or for the request timeout on a bad connection.
 - `-getSpotlightURLWithParams:callback:` — **network**, for Core Spotlight indexing. Takes its
   params directly and reads no link properties.

 On a server error the short-URL terminals hand back a **long-link fallback**, not nil — so a
 non-nil URL is not proof of success. Check `error`.

 */
@interface BranchLinkBuilder : NSObject

#pragma mark - Link content

/// Link parameters. Base64-encoded into long URLs; sent as the link's data on short-link requests.
/// Branch-reserved keys (`$og_title`, `$desktop_url`, …) control link behavior; anything else is
/// passed through to your app.
///
/// Read by every terminal except `-getSpotlightURLWithParams:callback:`, which takes its params as
/// an argument instead.
@property (nonatomic, copy, nullable) NSDictionary *params;

#pragma mark - Initialization

- (instancetype)init;

#pragma mark - Terminals

/**
 Requests a short Branch link, **blocking the calling thread** until the server responds.

 Equivalent to `-getShortURLWithLinkProperties:ignoreUAString:` with a nil `ignoreUAString`.

 @param linkProperties The link's content and behavior. May be nil, in which case every option takes
        its default.
 @return The short URL; a long-URL fallback on a server error; or nil.
 */
- (nullable NSString *)getShortURLWithLinkProperties:(nullable BranchLinkProperties *)linkProperties
    NS_SWIFT_NAME(getShortURLSynchronously(withLinkProperties:));

/**
 Requests a short Branch link, **blocking the calling thread** until the server responds.

 Do not call this on the main thread. It performs a synchronous network round trip, so on the main
 thread it freezes the UI for the duration and, on a slow or unreachable network, for the full
 request timeout.

 Successful results are cached: a second call with identical link options returns the cached URL
 without a request. Passing an `ignoreUAString` bypasses that cache read, so the call always reaches
 the network.

 If the server returns a non-200, the SDK falls back to a long link built from the last known link
 domain — so a non-nil result is not proof the request succeeded. That fallback is not cached, so a
 later call retries the request. When no link domain is known yet, the fallback returns nil.

 If `+[Branch initialize:]` has not run there is no instance to send the request through: the call
 logs a `BNCInitError` and returns nil without reaching the network.

 In Swift both blocking terminals are named `getShortURLSynchronously(…)`, so neither can be reached
 by mistake from an `async` context in place of the non-blocking terminal.

 @param linkProperties The link's content and behavior. May be nil, in which case every option takes
        its default.
 @param ignoreUAString A User-Agent string the Branch backend should ignore, so a link preview
        scrape is not counted as a click. It is not part of the link's cache key, so a link fetched
        with one can still be served to a later call that passes nil.
 @return The short URL; a long-URL fallback on a server error; or nil.
 */
- (nullable NSString *)getShortURLWithLinkProperties:(nullable BranchLinkProperties *)linkProperties
                                      ignoreUAString:(nullable NSString *)ignoreUAString
    NS_SWIFT_NAME(getShortURLSynchronously(withLinkProperties:ignoreUAString:));

/**
 Requests a short Branch link without blocking, delivering it to `callback`.

 Prefer this over the blocking terminals everywhere, and especially on the main thread.

 The callback is invoked on the **main queue**, so it is safe to update UI from it directly. On a
 server error the callback receives a long-link fallback together with the error, rather than a nil
 URL — check `error`, not the URL, to decide whether the request succeeded.

 Results share the same cache as the blocking terminals: a second call with identical link options
 calls back with the cached URL and issues no request.

 There is no `ignoreUAString` on this path: a link whose first click should not be counted is only
 ever requested through `-getShortURLWithLinkProperties:ignoreUAString:`.

 If `+[Branch initialize:]` has not run there is no instance to send the request through: the
 callback receives a nil URL and a `BNCInitError`, and nothing reaches the network.

 @param linkProperties The link's content and behavior. May be nil, in which case every option takes
        its default.
 @param callback Receives the short URL, or a long-link fallback plus an error. May be nil, in which
        case the link is still created and cached.
 */
- (void)getShortURLWithParamsWithLinkProperties:(nullable BranchLinkProperties *)linkProperties
                                       callback:(nullable callbackWithUrl)callback
    NS_SWIFT_NAME(getShortURL(withLinkProperties:callback:));

/**
 Builds a long Branch link offline, with no network call.

 The link's `params` are JSON-encoded, base64'd and percent-encoded into the URL's `data` query
 item, so the whole link is self-describing and can be produced with no connectivity and no round
 trip. That also makes it long — prefer a short link where the URL is user-visible.

 A long URL has no campaign parameter, so `linkProperties.campaign` is silently unused.

 This is the one terminal that does not require `+[Branch initialize:]` to have run: it needs only
 a Branch key, which it also reads from `branch.json` or the `branch_key` Info.plist entry.

 @param linkProperties The link's content and behavior. May be nil, in which case every option takes
        its default.
 @param useAppLinkDomain When YES, the link is built against your app.link domain instead of the
        default link domain.
 @return The long URL, or nil if the Branch key is unavailable.
 */
- (nullable NSString *)getLongURLWithLinkProperties:(nullable BranchLinkProperties *)linkProperties
                                   useAppLinkDomain:(BOOL)useAppLinkDomain
    NS_SWIFT_NAME(getLongURL(withLinkProperties:useAppLinkDomain:));

/**
 Requests the Branch link used to attribute a Core Spotlight index entry, delivering the server's
 response to `callback`.

 This is the terminal behind Spotlight indexing. Unlike the other short-link terminals it calls back
 with the server's whole link payload rather than just a URL, because Core Spotlight needs the
 accompanying fields — the URL alone is under the `url` key.

 A Spotlight link is not an ordinary link, and the SDK fixes its shape: it is always created with a
 channel of `spotlight`, and it takes no link properties. Its params come from this method's
 argument, not from the `params` property, which it does not read.

 Results are **not** cached — every call reaches the network, where the two short-URL terminals
 share a link cache.

 The callback is invoked on the **main thread**. On a server error it receives an empty dictionary
 together with the error, rather than nil.

 If `+[Branch initialize:]` has not run there is no instance to send the request through: the
 callback receives an empty dictionary and a `BNCInitError`, and nothing reaches the network.

 @param params The link's data payload.
 @param callback Receives the server's link payload, or an empty dictionary plus an error. May be
        nil, in which case the link is still created.
 */
- (void)getSpotlightURLWithParams:(nullable NSDictionary *)params
                         callback:(nullable callbackWithParams)callback;

@end

NS_ASSUME_NONNULL_END
