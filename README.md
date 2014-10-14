## Installation

compiled SDK size: ~155kb

### Available in CocoaPods

Branch is available through [CocoaPods](http://cocoapods.org), to install it simply add the following line to your Podfile:

    pod "Branch"

#### Or download the raw files

Download code from here:
https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-SDK.zip

The testbed project:
https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-TestBed.zip

Or just clone this project!

### Register you app

You can sign up for your own app id at http://dashboard.branchmetrics.io

## Configuration (for tracking)

Ideally, you want to use our links any time you have an external link pointing to your app (share, invite, referral, etc) because:

1. Our dashboard can tell you where your installs are coming from
1. Our links are the highest possible converting channel to new downloads and users
1. You can pass that shared data across install to give new users a custom welcome or show them the content they expect to see

Our linking infrastructure will support anything you want to build. If it doesn't, we'll fix it so that it does: just reach out to alex@branchmetrics.io with requests.

### Register a URI scheme direct deep linking (optional but recommended)

You can register your app to respond to direct deep links (yourapp:// in a mobile browser) by adding a URI scheme in the YourProject-Info.plist file. Also, make sure to change **yourapp** to a unique string that represents your app name.

1. In Xcode, click on YourProject-Info.plist on the left.
1. Find URL Types and click the right arrow. (If it doesn't exist, right click anywhere and choose Add Row. Scroll down and choose URL Types)
1. Add "yourapp", where yourapp is a unique string for your app, as an item in URL Schemes as below:

![URL Scheme Demo](https://s3-us-west-1.amazonaws.com/branchhost/urlScheme.png)

### Initialize SDK And Register Deep Link Routing Function

Called when app first initializes a session, ideally in the app delegate. If you created a custom link with your own custom dictionary data, you probably want to know when the user session init finishes, so you can check that data. Think of this callback as your "deep link router". If your app opens with some data, you want to route the user depending on the data you passed in. Otherwise, send them to a generic install flow.

This deep link routing callback is called 100% of the time on init, with your link params or an empty dictionary if none present.

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// your other init code


	// sign up to get your key at http://branch.io
	Branch *branch = [Branch getInstance:@"Your app key"];
	[branch initUserSessionWithCallback:^(NSDictionary *params) {
		// params are the deep linked params associated with the link that the user clicked before showing up
		// params will be empty if no data found


		// here is the data from the example below if a new user clicked on Joe's link and installed the app
		NSString *name = [params objectForKey:@"user"]; // returns Joe
		NSString *profileUrl = [params objectForKey:@"profile_pic"]; // returns https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg
		NSString *description = [params objectForKey:@"description"]; // returns Joe likes long walks on the beach...

		// route to a profile page in the app for Joe
		// show a customer welcome
	} withLaunchOptions:launchOptions];
}
```

```objc
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	// pass the url to the handle deep link call
	// if handleDeepLink returns YES, and you registered a callback in initUserSession, the callback will be called with the data associated with the deep link
	if (![[Branch getInstance] handleDeepLink:url]) {
		// do other deep link routing for the Facebook SDK, Pinterest SDK, etc
	}
    return YES;
}
```

#### Retrieve session (install or open) parameters

These session parameters will be available at any point later on with this command. If no params, the dictionary will be empty. This refreshes with every new session (app installs AND app opens)
```objc
NSDictionary *sessionParams = [[Branch getInstance] getReferringParams];
```

#### Retrieve install (install only) parameters

If you ever want to access the original session params (the parameters passed in for the first install event only), you can use this line. This is useful if you only want to reward users who newly installed the app from a referral link or something.
```objc
NSDictionary *installParams = [[Branch getInstance] getInstallReferringParams];
```

### Persistent identities

Often, you might have your own user IDs, or want referral and event data to persist across platforms or uninstall/reinstall. It's helpful if you know your users access your service from different devices. This where we introduce the concept of an 'identity'.

To identify a user, just call:
```objc
[[Branch getInstance] identifyUser:@"your user id"];
```

#### Logout

If you provide a logout function in your app, be sure to clear the user when the logout completes. This will ensure that all the stored parameters get cleared and all events are properly attributed to the right identity.

**Warning** this call will clear the referral credits and attribution on the device.

```objc
[[Branch getInstance] clearUser];
```

### Register custom events

```objc
Branch *branch = [Branch getInstance];
[branch userCompletedAction:@"your_custom_event"]; 
```

OR if you want to store some state with the event

```objc
Branch *branch = [Branch getInstance];
[branch userCompletedAction:@"your_custom_event" withState:(NSDictionary *)appState]; 
```

Some example events you might want to track:
```objc
@"complete_purchase"
@"wrote_message"
@"finished_level_ten"
```

## Generate Tracked, Deep Linking URLs (pass data across install and open)

### Shortened links

There are a bunch of options for creating these links. You can tag them for analytics in the dashboard, or you can even pass data to the new installs or opens that come from the link click. How awesome is that? You need to pass a callback for when you link is prepared (which should return very quickly, ~ 100 ms to process). If you don't want a callback, and can tolerate long links, you can explore the getLongUrl method family.

```objc
// associate data with a link
// you can access this data from any instance that installs or opens the app from this link (amazing...)

NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

[params setObject:@"Joe" forKey:@"user"];
[params setObject:@"https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg" forKey:@"profile_pic"];
[params setObject:@"Joe likes long walks on the beach..." forKey:@"description"];

// associate a url with a set of tags, channel, feature, and stage for better analytics.
// tags: null or example set of tags could be "version1", "trial6", etc
// channel: null or examples: "facebook", "twitter", "text_message", etc
// feature: null or examples: Branch.FEATURE_TAG_SHARE, Branch.FEATURE_TAG_REFERRAL, "unlock", etc
// stage: null or examples: "past_customer", "logged_in", "level_6"

Branch *branch = [Branch getInstance];
[branch getShortUrlWithParams:params andTags:@[@"version1", @"trial6"] andChannel:@"text_message" andFeature:BRANCH_FEATURE_TAG_SHARE andStage:@"level_6" andCallback:^(NSString *url) {
	// show the link to the user or share it immediately
}];
```

There are other methods which exclude tag and data if you don't want to pass those. Explore Xcode's autocomplete functionality.

**Note** 
You can customize the Facebook OG tags of each URL if you want to dynamically share content by using the following optional keys in the params dictionary:
```objc
@"$og_app_id"
@"$og_title"
@"$og_description"
@"$og_image_url"
```

Also, you do custom redirection by inserting the following optional keys in the dictionary. For example, if you want to send users on the desktop to a page on your website, insert the $desktop_url with that URL value
```objc
@"$desktop_url"
@"$android_url"
@"$ios_url"
@"$ipad_url"
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

```objc
[[Branch getInstance] loadRewardsWithCallback:^(BOOL changed) {
	// changed boolean will indicate if the balance changed from what is currently in memory

	// will return the balance of the current user's credits
	NSInteger credits = [[Branch getInstance] getCredits];
}];
```

### Redeem all or some of the reward balance (store state)

We will store how many of the rewards have been deployed so that you don't have to track it on your end. In order to save that you gave the credits to the user, you can call redeem. Redemptions will reduce the balance of outstanding credits permanently.

```objc
// Save that the user has redeemed 5 credits
[[Branch getInstance] redeemRewards:5];
```
