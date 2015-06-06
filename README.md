# Branch Metrics iOS SDK

This is the repository of our open source iOS SDK. There's a full demo app embedded in this repository, but you should also check out our live demo: [Branch Monster Factory](https://itunes.apple.com/us/app/id917737838). We've [open sourced the Branchster's app](https://github.com/BranchMetrics/Branchster-iOS) as well if you'd like to dig in.


## [New documentation portal](https://dev.branch.io)

Check out our new doc portal!

## Important migration to v0.7.8
The `source:iOS` attribute has been removed from the params dictionary for links. However, a bunch of constants have been added that are added by the Branch backend to link clicks and opens. If you were relying on the source attribute in the past, you can now find that via the `BRANCH_INIT_KEY_CREATION_SOURCE`.

## Important migration to v0.6.0

We have deprecated the bnc_app_key and replaced that with the new branch_key. Please see [add branch key](#add-your-branch-key-to-your-project) for details.


## FAQ

1 __What if you go down?! Or there is a poor connection?__

At Branch, we live and breathe uptime and performance. Just in case, we've got mechanisms internal to the SDK to deal with network issues. We always call the callbacks with the error parameter describing the issue. If the phone is in airplane mode and the connection is not available, the callbacks are called immediately. If there is a server latency, we timeout after 3 seconds and will retry 5 more times with a 3 second pause in between each. These timeouts are adjustable on the singleton instance by calling `setNetworkTimeout` (s), `setMaxRetries` and `setRetryInterval` (s).

2 __How can I debug/test the SDK__

Just call setDebug after you get a reference to the Branch singleton. We'll log all requests. Even more importantly, we won't reference the hardware ID of the phone so you can register installs after just uninstalling/reinstalling the app.

_Make sure to remove `setDebug` before releasing._

3 __Why do I not see any installs when I reinstall?__

We do a lot of smart things to give you an accurate read on the number of installs you actually have. The most common one is associating the user with the actual hardware ID of the phone. If a user uninstalls the app, then reinstalls, we'll know it's the same person from before and just register and 'open' instead of an 'install'. To register an install on the same phone again, see FAQ #2 about debugging.

4 __Facebook deep links seem to not work?__

Branch uses the Facebook App Links protocol to pass the deep links through to your app from Facebook. Funny enough, if you also have a Facebook app configured in the developer portal and you choose 'Deep link from feed', Facebook ignores its own protocol. Make sure to *uncheck* this option in your Facebook app.

## Installation

compiled SDK size: ~155kb

### Available in CocoaPods

Branch is available through [CocoaPods](http://cocoapods.org), to install it simply add the following line to your Podfile:

    pod "Branch"

#### Or download the raw files

Download code from here:
[https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-SDK.zip](https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-SDK.zip)

The testbed project:
[https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-TestBed.zip](https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-TestBed.zip)

Or just clone this project!

### Register you app

You can sign up for your own app id at [https://dashboard.branch.io](https://dashboard.branch.io)

## Configuration (for tracking)

Ideally, you want to use our links any time you have an external link pointing to your app (share, invite, referral, etc) because:

1. Our dashboard can tell you where your installs are coming from
1. Our links are the highest possible converting channel to new downloads and users
1. You can pass that shared data across install to give new users a custom welcome or show them the content they expect to see

Our linking infrastructure will support anything you want to build. If it doesn't, we'll fix it so that it does: just reach out to alex@branch.io with requests.

### Register a URI scheme direct deep linking (optional but recommended)

You can register your app to respond to direct deep links (yourapp:// in a mobile browser) by adding a URI scheme in the YourProject-Info.plist file. Make sure to change **yourapp** to a unique string that represents your app name.

1. In Xcode, click on YourProject-Info.plist on the left.
1. Find URL Types and click the right arrow. (If it doesn't exist, right click anywhere and choose Add Row. Scroll down and choose URL Types)
1. Add "yourapp", where yourapp is a unique string for your app, as an item in URL Schemes as below:

![URL Scheme Demo](https://s3-us-west-1.amazonaws.com/branchhost/urlScheme.png)

Alternatively, you can add the URI scheme in your project's Info page.

1. In Xcode, click your project in the Navigator (on the left side).
1. Select the "Info" tab.
1. Expand the "URL Types" section at the bottom.
1. Click the "+" sign to add a new URI Scheme, as below:

![URL Scheme Demo](https://s3-us-west-1.amazonaws.com/branchhost/urlType.png)

### Add your Branch Key to your project

After you register your app, your Branch Key can be retrieved on the [Settings](https://dashboard.branch.io/#/settings) page of the dashboard. Now you need to add it to YourProject-Info.plist (Info.plist for Swift).

1. In plist file, mouse hover "Information Property List" which is the root item under the Key column.
1. After about half a second, you will see a "+" sign appear. Click it.
1. In the newly added row, fill in "branch_key" for its key, leave type as String, and enter your app's Branch Key obtained in above steps in the value column.
1. Save the plist file.

###### URI Scheme Considerations
The Branch SDK will pull the first URI Scheme from your list that is not one of `fb`, `db`, or `pin`. This value will be used one time to set the iOS URI Scheme under your Link Settings in the Branch Dashboard.

![Branch Key Demo](docs/images/branch-key-plist.png)

If you want to add key for both your live and test apps at the same time, you need change the type column to Dictionary, and add two entries inside:
1. For live app, use "live" (without double quotes) for key, String for type, and your live branch key for value
1. For test app, use "test" (without double quotes) for key, String for type, and your test branch key for value

![Branch Multi Key Demo](docs/images/branch-multi-key-plist.png)

For additional help configuring the SDK, including step-by-step instructions, please see the [iOS Quickstart Guide](https://github.com/BranchMetrics/Branch-Integration-Guides/blob/master/ios-quickstart.md).

### Get A Singleton Branch Instance

All Branch methods require an instance of the main Branch object. Here's how you grab one. It's stored statically and is accessible from any class.

#### Method

**Live:** To retrieve the main instance, use this method.

###### Objective-C
```objc
Branch *branch = [Branch getInstance];
```
###### Swift
```swift
let branch: Branch = Branch.getInstance()
```

**Test:** To retrieve and instance with the test key stored in plist, use this method. This will also enable debug and log all Branch requests to the console.

###### Objective-C
```objc
#warning Remove for launch
Branch *branch = [Branch getTestInstance];
```
###### Swift
```swift
//TODO: Remove for launch
let branch: Branch = Branch.getTestInstance();
```

#### Arguments

**Branch key** (NSString *) _optional_
: If you don't store the Branch key in the plist file, you have the option of passing this key as an argument


### Init Branch Session And Deep Link Routing Function

To deep link, Branch must initialize a session to check if the user originated from a link. This call will initialize a new session _every time the app opens_. 100% of the time the app opens, it will call the deep link handling block to inform you whether the user came from a link. If your app opens with keys in the params, you'll want to route the user depending on the data you passed in. Otherwise, send them to a generic screen.

Call this in 

#### Method

###### Objective-C
```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    Branch *branch = [Branch getInstance];
    [branch initSessionWithLaunchOptions:launchOptions isReferrable:YES andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {    
    	// route the user based on what's in params
    }];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if (![[Branch getInstance] handleDeepLink:url]) {
        // do other deep link routing for the Facebook SDK, Pinterest SDK, etc
    }
    return YES;
}
```
###### Swift
```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    let branch: Branch = Branch.getInstance()
    branch.initSessionWithLaunchOptions(launchOptions, true, andRegisterDeepLinkHandler: { params, error in
    	// route the user based on what's in params
    })
    return true
}

func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
    if (!Branch.getInstance().handleDeepLink(url)) {
        // do other deep link routing for the Facebook SDK, Pinterest SDK, etc
    }

    return true
}
```

#### Arguments

###### initSession

**launchOptions** (NSDictionary *) _required_
: These launch options are passed to Branch through didFinishLaunchingWithOptions and will notify us if the user originated from a URI call or not. If the app was opened from a URI like myapp://, we need to follow a special initialization routine.

**deepLinkHandler** ^(NSDictionary *params, NSError *error) _optional_
: This is the callback block that Branch will execute after a network call to determine where the user comes from. It is called 100% of the time the app opens up since Branch registers for lifecycle notifications.

- _NSDictionary *params_ : These params will contain any data associated with the Branch link that was clicked before the app session began. There are a few keys which are always present: 
	- '+is_first_session' Denotes whether this is the first session (install) or any other session (open)
	- '+clicked_branch_link' Denotes whether or not the user clicked a Branch link that triggered this session
- _NSError *error_ : This error will be nil unless there is an error such as connectivity or otherwise. Check !error to confirm it was a valid link.
    - BNCServerProblemError There was an issue connecting to the Branch service
    - BNCBadRequestError The request was improperly formatted

**isReferrable** (BOOL) _optional_
: This boolean lets you control whether or not the user is eligible to be 'referred'. This is applicable for credits and influencer tracking. If isReferrable is set to NO | false, and the user clicks a link before entering the app, deep link parameters will appear but that user will _not_ be considered referred. If isReferrable is set to YES | true, and the user clicks a link, deep link params will appear and the user _will_ be considered referred. Remove this argument to access the default, which only allows the user to be referred on a _fresh install_ but not on opens.

###### handleDeepLink

**url** (NSString *) _required_
: This argument passes us the URI string so that we can parse the extra parameters. For example, 'myapp://open?link_click_id=12345'.

#### Returns

###### initSession

Nothing

###### handleDeepLink

**BOOL** handleDeepLink will return a boolean indicating whether Branch has handled the URI. If the URI call is 'myapp://open?link_click_id=12345', then handleDeepLink will return YES because the Branch click object is present. If just 'myapp://', handleDeepLink will return NO.

#### Retrieve session (install or open) parameters

These session parameters will be available at any point later on with this command. If no params, the dictionary will be empty. This refreshes with every new session (app installs AND app opens)

###### Objective-C

```objc
NSDictionary *sessionParams = [[Branch getInstance] getLatestReferringParams];
```

###### Swift

```swift
let sessionParams = Branch.getInstance().getLatestReferringParams()
```

#### Arguments

None

#### Returns

**NSDictionary *** When initSession returns a parameter set in the deep link callback, we store it in NSUserDefaults for the duration of the session in case you want to retrieve it later. Careful, once the app is minimized and the session ends, this will be cleared.

#### Retrieve install (install only) parameters

If you ever want to access the original session params (the parameters passed in for the first install event only), you can use this line. This is useful if you only want to reward users who newly installed the app from a referral link or something.

###### Objective-C

```objc
NSDictionary *installParams = [[Branch getInstance] getFirstReferringParams]; // previously getInstallReferringParams
```

###### Swift

```swift
let installParams = Branch.getInstance().getFirstReferringParams() // previously getInstallReferringParams
```

### Persistent identities

Often, you might have your own user IDs, or want referral and event data to persist across platforms or uninstall/reinstall. It's helpful if you know your users access your service from different devices. This where we introduce the concept of an 'identity'.

To identify a user, just call:

###### Objective-C

```objc
// previously identifyUser:
[[Branch getInstance] setIdentity:your user id];    // your user id should not exceed 127 characters
```

###### Swift

```swift
// previously identifyUser:
Branch.getInstance().setIdentity(your user id)  // your user id should not exceed 127 characters
```

#### Logout

If you provide a logout function in your app, be sure to clear the user when the logout completes. This will ensure that all the stored parameters get cleared and all events are properly attributed to the right identity.

**Warning** this call will clear the referral credits and attribution on the device.

###### Objective-C

```objc
[[Branch getInstance] logout];  // previously clearUser
```

###### Swift

```swift
Branch.getInstance().logout()   // previously clearUser
```

### Register custom events

###### Objective-C

```objc
[[Branch getInstance] userCompletedAction:@"your_custom_event"]; // your custom event name should not exceed 63 characters
```

###### Swift

```swift
Branch.getInstance().userCompletedAction("your_custom_event") // your custom event name should not exceed 63 characters
```

OR if you want to store some state with the event:

###### Objective-C

```objc
[[Branch getInstance] userCompletedAction:@"your_custom_event" withState:(NSDictionary *)appState]; // same 63 characters max limit
```

###### Swift

```swift
Branch.getInstance().userCompletedAction("your_custom_action", withState: [String: String]()) // same 63 characters max limit; replace [String: String]() with params dictionary
```

Some example events you might want to track:

```objc
@"complete_purchase"
@"wrote_message"
@"finished_level_ten"
```

## Generate Tracked, Deep Linking URLs (pass data across install and open)

### Shortened links

There are a bunch of options for creating these links. You can tag them for analytics in the dashboard, or you can even pass data to the new installs or opens that come from the link click. How awesome is that? You need to pass a callback for when you link is prepared (which should return very quickly, ~ 50 ms to process).

#### Encoding Note
One quick note about encoding. Since `NSJSONSerialization` supports a limited set of classes, we do some custom encoding to allow additional types. Current supported types include `NSDictionary`, `NSArray`, `NSURL`, `NSString`, `NSNumber`, `NSNull`, and `NSDate` (encoded as an ISO8601 string with timezone). If a parameter is of an unknown type, it will be ignored.


For more details on how to create links, see the [Branch link creation guide](https://github.com/BranchMetrics/Branch-Integration-Guides/blob/master/url-creation-guide.md)

###### Objective-C

```objc
// associate data with a link
// you can access this data from any instance that installs or opens the app from this link (amazing...)

NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

[params setObject:@"Joe" forKey:@"user"];
[params setObject:@"https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg" forKey:@"profile_pic"];
[params setObject:@"Joe likes long walks on the beach..." forKey:@"description"];

// Customize the display of the link
[params setObject:@"Joe's My App Referral" forKey:@"$og_title"];
[params setObject:@"https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg" forKey:@"$og_image_url"];
[params setObject:@"Join Joe in My App - it's awesome" forKey:@"$og_description"];

// Customize the redirect performance
[params setObject:@"http://myapp.com/desktop_splash" forKey:@"$desktop_url"];

// associate a url with a set of tags, channel, feature, and stage for better analytics.
// tags: nil or example set of tags could be "version1", "trial6", etc; each tag should not exceed 64 characters
// channel: nil or examples: "facebook", "twitter", "text_message", etc; should not exceed 128 characters
// feature: nil or examples: FEATURE_TAG_SHARE, FEATURE_TAG_REFERRAL, "unlock", etc; should not exceed 128 characters
// stage: nil or examples: "past_customer", "logged_in", "level_6"; should not exceed 128 characters

// Link 'type' can be used for scenarios where you want the link to only deep link the first time.
// Use nil, BranchLinkTypeUnlimitedUse or BranchLinkTypeOneTimeUse

// Link 'alias' can be used to label the endpoint on the link. For example: http://bnc.lt/AUSTIN28. Should not exceed 128 characters
// Be careful about aliases: these are immutable objects permanently associated with the data and associated paramters you pass into the link. When you create one in the SDK, it's tied to that user identity as well (automatically specified by the Branch internals). If you want to retrieve the same link again, you'll need to call getShortUrl with all of the same parameters from before.

Branch *branch = [Branch getInstance];
[branch getShortURLWithParams:params andTags:@[@"version1", @"trial6"] andChannel:@"text_message" andFeature:BRANCH_FEATURE_TAG_SHARE andStage:@"level_6" andAlias:@"AUSTIN68" andCallback:^(NSString *url, NSError *error) {
    // show the link to the user or share it immediately
}];

// The callback will return null if the link generation fails (or if the alias specified is aleady taken.)
```

###### Swift

```swift
// associate data with a link
// you can access this data from any instance that installs or opens the app from this link (amazing...)

var params = ["user": "Joe"]
params["profile_pic"] = "https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg"
params["description"] = "Joe likes long walks on the beach..."

// Customize the display of the link
params["$og_title"] = "Joe's My App Referral"
params["$og_image_url"] = "https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg"
params["$og_description"] = "Join Joe in My App - it's awesome"

// Customize the redirect performance
params["$desktop_url"] = "http://myapp.com/desktop_splash"

// associate a url with a set of tags, channel, feature, and stage for better analytics.
// tags: nil or example set of tags could be "version1", "trial6", etc; each tag should not exceed 64 characters
// channel: nil or examples: "facebook", "twitter", "text_message", etc; should not exceed 128 characters
// feature: nil or examples: FEATURE_TAG_SHARE, FEATURE_TAG_REFERRAL, "unlock", etc; should not exceed 128 characters
// stage: nil or examples: "past_customer", "logged_in", "level_6"; should not exceed 128 characters

// Link 'type' can be used for scenarios where you want the link to only deep link the first time.
// Use nil, BranchLinkTypeUnlimitedUse or BranchLinkTypeOneTimeUse

// Link 'alias' can be used to label the endpoint on the link. For example: http://bnc.lt/AUSTIN28. Should not exceed 128 characters
// Be careful about aliases: these are immutable objects permanently associated with the data and associated paramters you pass into the link. When you create one in the SDK, it's tied to that user identity as well (automatically specified by the Branch internals). If you want to retrieve the same link again, you'll need to call getShortUrl with all of the same parameters from before.

// The callback will return null if the link generation fails (or if the alias specified is aleady taken.)

Branch.getInstance().getShortURLWithParams(params, andTags: ["version1", "trial6"], andChannel: "text_message", andFeature: BRANCH_FEATURE_TAG_SHARE, andStage: "level_6", andAlias: "AUSTIN68", andCallback: { (url: String!, error: NSError!) -> Void in
    if (error == nil) {
        // show the link to the user or share it immediately
    }
})
```

There are other methods which exclude tag and data if you don't want to pass those. Explore Xcode's autocomplete functionality.

**Note**
You can customize the Facebook OG tags of each URL if you want to dynamically share content by using the following _optional keys in the data dictionary_. Please use this [Facebook tool](https://developers.facebook.com/tools/debug/og/object) to debug your OG tags!

| Key | Value
| --- | ---
| "$og_title" | The title you'd like to appear for the link in social media
| "$og_description" | The description you'd like to appear for the link in social media
| "$og_image_url" | The URL for the image you'd like to appear for the link in social media
| "$og_video" | The URL for the video
| "$og_url" | The URL you'd like to appear
| "$og_redirect" | If you want to bypass our OG tags and use your own, use this key with the URL that contains your site's metadata.

Also, you do custom redirection by inserting the following _optional keys in the dictionary_:

| Key | Value
| --- | ---
| "$desktop_url" | Where to send the user on a desktop or laptop. By default it is the Branch-hosted text-me service
| "$android_url" | The replacement URL for the Play Store to send the user if they don't have the app. _Only necessary if you want a mobile web splash_
| "$ios_url" | The replacement URL for the App Store to send the user if they don't have the app. _Only necessary if you want a mobile web splash_
| "$ipad_url" | Same as above but for iPad Store
| "$fire_url" | Same as above but for Amazon Fire Store
| "$blackberry_url" | Same as above but for Blackberry Store
| "$windows_phone_url" | Same as above but for Windows Store
| "$after_click_url" | When a user returns to the browser after going to the app, take them to this URL. _iOS only; Android coming soon_

You have the ability to control the direct deep linking of each link by inserting the following _optional keys in the dictionary_:

| Key | Value
| --- | ---
| "$deeplink_path" | The value of the deep link path that you'd like us to append to your URI. For example, you could specify "$deeplink_path": "radio/station/456" and we'll open the app with the URI "yourapp://radio/station/456?link_click_id=branch-identifier". This is primarily for supporting legacy deep linking infrastructure.
| "$always_deeplink" | true or false. (default is not to deep link first) This key can be specified to have our linking service force try to open the app, even if we're not sure the user has the app installed. If the app is not installed, we fall back to the respective app store or $platform_url key. By default, we only open the app if we've seen a user initiate a session in your app from a Branch link (has been cookied and deep linked by Branch)

### UIActivityView Share Sheet

UIActivityView is the standard way of allowing users to share content from your app. A common use case is a user sharing a referral code, or a content URL with their friends. If you want to give your users a way of sharing content from your app, this is the simplest way to implement Branch.

**Sample UIActivityView Share sheet**

![UIActivityView Share Sheet](https://s3-us-west-1.amazonaws.com/branchhost/iOSShareSheet.png )

The Branch iOS SDK includes a subclassed UIActivityItemProvider that can be passed into a UIActivityViewController, that will generate a Branch short URL and automatically tag it with the channel the user selects (Facebook, Twitter, etc.).

**Note**: This method was formerly getBranchActivityItemWithDefaultURL:, which is now deprecated. Rather than requiring a default URL that acts as a placeholder for UIActivityItemProvider, a longURL is generated instantly and synchronously.

The sample app included with the Branch iOS SDK shows a sample of this in ViewController.m:
###### Objective-C

```objc
// Setup up the content you want to share, and the Branch
// params and properties, as you would for any branch link

// No need to set the channel, that is done automatically based
// on the share activity the user selects
NSString *shareString = @"Super amazing thing I want to share!";
UIImage *amazingImage = [UIImage imageNamed:@"Super-Amazing-Image.png"];

NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

[params setObject:@"Joe" forKey:@"user"];
[params setObject:@"https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg" forKey:@"profile_pic"];
[params setObject:@"Joe likes long walks on the beach..." forKey:@"description"];

// Customize the display of the link
[params setObject:@"Joe's My App Referral" forKey:@"$og_title"];
[params setObject:@"https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg" forKey:@"$og_image_url"];
[params setObject:@"Join Joe in My App - it's awesome" forKey:@"$og_description"];

// Customize the redirect performance
[params setObject:@"http://myapp.com/desktop_splash" forKey:@"$desktop_url"];

NSArray *tags = @[@"tag1", @"tag2"];
NSString *feature = @"invite";
NSString *stage = @"2";

// Branch UIActivityItemProvider
UIActivityItemProvider *itemProvider = [Branch getBranchActivityItemWithParams:params andFeature:feature andStage:stage andTags:tags];

// Pass this in the NSArray of ActivityItems when initializing a UIActivityViewController
UIActivityViewController *shareViewController = [[UIActivityViewController alloc] initWithActivityItems:@[shareString, amazingImage, itemProvider] applicationActivities:nil];

// Present the share sheet!
[self.navigationController presentViewController:shareViewController animated:YES completion:nil];
```

###### Swift

```swift
// Setup up the content you want to share, and the Branch
// params and properties, as you would for any branch link

// No need to set the channel, that is done automatically based
// on the share activity the user selects
var items: Array = [AnyObject]()

let shareString = "Super amazing thing I want to share!"
items.append(shareString)
if let amazingImage: UIImage = UIImage(named: "mada.png") {
    items.append(amazingImage)
}

var params = ["user": "Joe"]
params["profile_pic"] = "https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg"
params["description"] = "Joe likes long walks on the beach..."

// Customize the display of the link
params["$og_title"] = "Joe's My App Referral"
params["$og_image_url"] = "https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg"
params["$og_description"] = "Join Joe in My App - it's awesome"

// Customize the redirect performance
params["$desktop_url"] = "http://myapp.com/desktop_splash"

let tags = ["tag1", "tag2"]
let feature = "invite"
let stage = "2"

// Branch UIActivityItemProvider
let itemProvider = Branch.getBranchActivityItemWithParams(params, andFeature: feature, andStage: stage, andTags: tags)
items.append(itemProvider)

// Pass this in the NSArray of ActivityItems when initializing a UIActivityViewController
let shareViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

// Present the share sheet!
self.navigationController?.presentViewController(shareViewController, animated: true, completion: nil)
```

## Referral system rewarding functionality

In a standard referral system, you have 2 parties: the original user and the invitee. Our system is flexible enough to handle rewards for all users for any actions. Here are a couple example scenarios:

1) Reward the original user for taking action (eg. inviting, purchasing, etc)

2) Reward the invitee for installing the app from the original user's referral link

3) Reward the original user when the invitee takes action (eg. give the original user credit when their the invitee buys something)

These reward definitions are created on the dashboard, under the 'Reward Rules' section in the 'Referrals' tab on the dashboard.

Warning: For a referral program, you should not use unique awards for custom events and redeem pre-identify call. This can allow users to cheat the system.

### Get reward balance

Reward balances change randomly on the backend when certain actions are taken (defined by your rules), so you'll need to make an asynchronous call to retrieve the balance. Here is the syntax:

###### Objective-C

```objc
[[Branch getInstance] loadRewardsWithCallback:^(BOOL changed, NSError *error) {
    // changed boolean will indicate if the balance changed from what is currently in memory

    // will return the balance of the current user's credits
    NSInteger credits = [[Branch getInstance] getCredits];
}];
```

###### Swift

```swift
Branch().loadRewardsWithCallback { (changed: Bool, error: NSError!) -> Void in
    // changed boolean will indicate if the balance changed from what is currently in memory

    // will return the balance of the current user's credits
    let credits = Branch().getCredits()
}
```

### Redeem all or some of the reward balance (store state)

We will store how many of the rewards have been deployed so that you don't have to track it on your end. In order to save that you gave the credits to the user, you can call redeem. Redemptions will reduce the balance of outstanding credits permanently.

###### Objective-C

```objc
// Save that the user has redeemed 5 credits
[[Branch getInstance] redeemRewards:5];
```

###### Swift

```swift
// Save that the user has redeemed 5 credits
Branch.getInstance().redeemRewards(5)
```

### Get credit history

This call will retrieve the entire history of credits and redemptions from the individual user. To use this call, implement like so:

###### Objective-C

```objc
[[Branch getInstance] getCreditHistoryWithCallback:^(NSArray *history, NSError *error) {
    if (!error) {
        // process history
    }
}];
```

###### Swift

```swift
Branch.getInstance().getCreditHistoryWithCallback { (history: [AnyObject]!, error: NSError!) -> Void in
    if (error == nil) {
        // process history
    }
}
```

The response will return an array that has been parsed from the following JSON:

```json
[
    {
        "transaction": {
                           "date": "2014-10-14T01:54:40.425Z",
                           "id": "50388077461373184",
                           "bucket": "default",
                           "type": 0,
                           "amount": 5
                       },
        "event" : {
            "name": "event name",
            "metadata": { your event metadata if present }
        },
        "referrer": "12345678",
        "referree": null
    },
    {
        "transaction": {
                           "date": "2014-10-14T01:55:09.474Z",
                           "id": "50388199301710081",
                           "bucket": "default",
                           "type": 2,
                           "amount": -3
                       },
        "event" : {
            "name": "event name",
            "metadata": { your event metadata if present }
        },
        "referrer": null,
        "referree": "12345678"
    }
]
```
**referrer**
: The id of the referring user for this credit transaction. Returns null if no referrer is involved. Note this id is the user id in developer's own system that's previously passed to Branch's identify user API call.

**referree**
: The id of the user who was referred for this credit transaction. Returns null if no referree is involved. Note this id is the user id in developer's own system that's previously passed to Branch's identify user API call.

**type**
: This is the type of credit transaction

1. _0_ - A reward that was added automatically by the user completing an action or referral
1. _1_ - A reward that was added manually
2. _2_ - A redemption of credits that occurred through our API or SDKs
3. _3_ - This is a very unique case where we will subtract credits automatically when we detect fraud

### Get referral code

Retrieve the referral code created by current user

###### Objective-C

```objc
[[Branch getInstance] getReferralCodeWithCallback:^(NSDictionary *params, NSError *error) {
    if (!error) {
        NSString *referralCode = [params objectForKey:@"referral_code"];
    }
}];
```

###### Swift

```swift
Branch.getInstance().getReferralCodeWithCallback { (params: [NSObject : AnyObject]!, error: NSError!) -> Void in
    if (error == nil) {
        let referralCode: AnyObject? = params["referral_code"]
    }
}
```

### Create referral code

Create a new referral code for the current user, only if this user doesn't have any existing non-expired referral code.

In the simplest form, just specify an amount for the referral code.
The returned referral code is a 6 character long unique alpha-numeric string wrapped inside the params dictionary with key @"referral_code".

**amount** _NSInteger_
: The amount of credit to redeem when user applies the referral code

###### Objective-C

```objc
// Create a referral code of 5 credits
[[Branch getInstance] getReferralCodeWithAmount:5
                                    andCallback:^(NSDictionary *params, NSError *error) {
                                        if (!error) {
                                            NSString *referralCode = [params objectForKey:@"referral_code"];
                                            // do whatever with referralCode
                                        }
                                    }
];
```

###### Swift

```swift
// Create a referral code of 5 credits
Branch.getInstance().getReferralCodeWithAmount(5, andCallback: { (params: [NSObject : AnyObject]!, error: NSError!) -> Void in
    if (error == nil) {
        let referralCode: AnyObject? = params["referral_code"]
        // do whatever with referralCode
    }
})
```

Alternatively, you can specify a prefix for the referral code.
The resulting code will have your prefix, concatenated with a 2 character long unique alpha-numeric string wrapped in the same data structure.

**prefix** _NSString*_
: The prefix to the referral code that you desire

###### Objective-C

```objc
// Create a referral code with prefix "BRANCH", 5 credits, and without an expiration date
[[Branch getInstance] getReferralCodeWithPrefix:@"BRANCH"   // prefix should not exceed 48 characters
                                         amount:5
                                    andCallback:^(NSDictionary *params, NSError *error) {
                                        if (!error) {
                                            NSString *referralCode = [params objectForKey:@"referral_code"];
                                            // do whatever with referralCode
                                        }
                                    }
];
```

###### Swift

```swift
// Create a referral code with prefix "BRANCH", 5 credits, and without an expiration date
// prefix should not exceed 48 characters
Branch.getInstance().getReferralCodeWithPrefix("BRANCH", amount: 5, andCallback: { (params: [NSObject : AnyObject]!, error: NSError!) -> Void in
    if (error == nil) {
        let referralCode: AnyObject? = params["referral_code"]
        // do whatever with referralCode
    }
})
```

If you want to specify an expiration date for the referral code, you can add an "expiration:" parameter.
The prefix parameter is optional here, i.e. it could be getReferralCodeWithAmount:expiration:andCallback.

**expiration** _NSDate*_
: The expiration date of the referral code

###### Objective-C

```objc
[[Branch getInstance] getReferralCodeWithPrefix:@"BRANCH"   // prefix should not exceed 48 characters
                                         amount:5
                                     expiration:[[NSDate date] dateByAddingTimeInterval:60 * 60 * 24]
                                    andCallback:^(NSDictionary *params, NSError *error) {
                                        if (!error) {
                                            NSString *referralCode = [params objectForKey:@"referral_code"];
                                            // do whatever with referralCode
                                        }
                                    }
];
```

###### Swift

```swift
// prefix should not exceed 48 characters
Branch.getInstance().getReferralCodeWithPrefix("BRANCH", amount: 5, expiration: NSDate().dateByAddingTimeInterval(60*60*24), andCallback: { (params: [NSObject : AnyObject]!, error: NSError!) -> Void in
    if (error == nil) {
        let referralCode: AnyObject? = params["referral_code"]
        // do whatever with referralCode
    }
})
```

You can also tune the referral code to the finest granularity, with the following additional parameters:

**bucket** _NSString*_
: The name of the bucket to use. If none is specified, defaults to 'default'

**calculation_type**  _ReferralCodeCalculation_
: This defines whether the referral code can be applied indefinitely, or only once per user

1. _BranchUnlimitedRewards_ - referral code can be applied continually
1. _BranchUniqueRewards_ - a user can only apply a specific referral code once

**location** _ReferralCodeLocation_
: The user to reward for applying the referral code

1. _BranchReferreeUser_ - the user applying the referral code receives credit
1. _BranchReferringUser_ - the user who created the referral code receives credit
1. _BranchBothUsers_ - both the creator and applicant receive credit

###### Objective-C

```objc
[[Branch getInstance] getReferralCodeWithPrefix:@"BRANCH"   // prefix should not exceed 48 characters
                                         amount:5
                                     expiration:[[NSDate date] dateByAddingTimeInterval:60 * 60 * 24]
                                         bucket:@"default"
                                calculationType:BranchUniqueRewards
                                       location:BranchBothUsers
                                    andCallback:^(NSDictionary *params, NSError *error) {
                                        if (!error) {
                                            NSString *referralCode = [params objectForKey:@"referral_code"];
                                            // do whatever with referralCode
                                        }
                                    }
];
```

###### Swift

```swift
// prefix should not exceed 48 characters
Branch.getInstance().getReferralCodeWithPrefix("BRANCH",
    amount: 5,
    expiration: NSDate().dateByAddingTimeInterval(60*60*24),
    bucket: "default",
    calculationType: BranchUniqueRewards,
    location: BranchBothUsers,
    andCallback: { (params: [NSObject : AnyObject]!, error: NSError!) -> Void in
    if (error == nil) {
        let referralCode: AnyObject? = params["referral_code"]
        // do whatever with referralCode
    }
})
```

### Validate referral code

Validate if a referral code exists in Branch system and is still valid.
A code is vaild if:

1. It hasn't expired.
1. If its calculation type is uniqe, it hasn't been applied by current user.

If valid, returns the referral code JSONObject in the call back.

**code** _NSString*_
: The referral code to validate

###### Objective-C

```objc
[[Branch getInstance] validateReferralCode:code andCallback:^(NSDictionary *params, NSError *error) {
    if (!error) {
        if ([code isEqualToString:[params objectForKey:@"referral_code"]]) {
            // valid
        } else {
            // invalid (should never happen)
        }
    } else {
        NSLog(@"Error in validating referral code: %@", error.localizedDescription);
    }
}];
```

###### Swift

```swift
Branch.getInstance().validateReferralCode(code, andCallback: { (params: [NSObject : AnyObject]!, error: NSError!) -> Void in
    if (error == nil) {
        if let returnedCode = params["referral_code"] as? String {
            // valid
        } else {
            // invalid (should never happen)
        }
    } else {
        NSLog(@"Error in validating referral code: %@", error.localizedDescription)
    }
})
```

### Apply referral code

Apply a referral code if it exists in Branch system and is still valid (see above). If the code is valid, returns the referral code JSONObject in the call back.

**code** _NSString*_
: The referral code to apply

###### Objective-C

```objc
[[Branch getInstance] applyReferralCode:code andCallback:^(NSDictionary *params, NSError *error) {
    if (!error) {
        // applied. you can get the referral code amount from the params and deduct it in your UI.
    } else {
        NSLog(@"Error in applying referral code: %@", error.localizedDescription);
    }
}];
```

###### Swift

```swift
Branch.getInstance().applyReferralCode(code, andCallback: { (params: [NSObject : AnyObject]!, error: NSError!) -> Void in
    if (error == nil) {
        // applied. you can get the referral code amount from the params and deduct it in your UI.
    } else {
        NSLog(@"Error in applying referral code: %@", error.localizedDescription);
    }
})
```

