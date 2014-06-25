## Installation

compiled SDK size: ~150kb

### Install library project

Download code from here:
https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-SDK.zip

The testbed project:
https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-TestBed.zip

Or just clone this project!

### Initialize SDK (registers install/open events)

Called when app first initializes a session. Please add these lines to the splash view controller that will be seen on app install.

Also, if you want to track open events from the links, you can add these lines before view did load.

```objc
#import "Branch.h"

Branch *branch = [Branch getInstance:@"Your app key"];
[branch initUserSession];
```

#### OR

If you created a custom link with your own custom dictionary data, you probably want to know when the user session init finishes, so you need to pass a block to handle the callback. If no params, the dictionary will be empty.

```objc
- (void)viewDidLoad {
	Branch *branch = [Branch getInstance:@"Your app key"];
	[branch initUserSessionWithCallback:^(NSDictionary *params) {
		// show the user some custom stuff or do some action based on what data you associate with a link
		// params will be empty if no data found


		// here is the data from the example below if a new user clicked on Joe's link and installed the app
		NSString *name = [params objectForKey:@"user"]; // returns Joe
		NSString *profileUrl = [params objectForKey:@"profile_pic"]; // returns https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg
		NSString *description = [params objectForKey:@"description"] // returns Joe likes long walks on the beach...
	}];
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

#### OR

We store these identities, and associate the referral connections among them. Therefore, if we see that you are identifying a user that already exists, we'll return the parameters associated with the first creation of that identity. You just need to register for the callback block.

```objc
[[Branch getInstance] identifyUser:@"your user id" withCallback:^(NSDictionary *params) {
	// here is the data from the example below if a new user clicked on Joe's link and installed the app
	NSString *name = [params objectForKey:@"user"]; // returns Joe
	NSString *profileUrl = [params objectForKey:@"profile_pic"]; // returns https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg
	NSString *description = [params objectForKey:@"description"] // returns Joe likes long walks on the beach...
}];
```

You can access these parameters at any time thereafter using this call.
```objc
NSDictionary *installParams = [[Branch getInstance] getInstallReferringParams];
```

#### Logout

If you provide a logout function in your app, be sure to clear the user when the logout completes. This will ensure that all the stored parameters get cleared and all events are properly attributed to the right identity.

```objc
[[Branch getInstance] clearUser];
```

### Register custom events

```objc
Branch *branch = [Branch getInstance];
[branch userCompletedAction:@"your_custom_event"]; 
```

Some example events you might want to track:
```objc
@"complete_purchase"
@"wrote_message"
@"finished_level_ten"
```

## Use

### Generate URLs

#### Short links (for social media sharing)

There are a bunch of options for creating these links. You can tag them for analytics in the dashboard, or you can even pass data to the new installs or opens that come from the link click. How awesome is that? All of the above options are the same (ie tagging, data passing) but you need to pass a callback. This will be called when you link is prepared (which should return very quickly, ~ 100 ms to process)

```objc
// get a simple url to track events with
Branch *branch = [Branch getInstance];
[branch getShortUrlWithCallback:^(NSString *url) {
	// show the link to the user or share it immediately
}];

// or 
// associate data with a link
// you can access this data from anyone instance that installs or opens the app from this link (amazing...)

NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

[params setObject:"Joe" forKey:@"user"];
[params setObject:"https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg" forKey:@"profile_pic"];
[params setObject:"Joe likes long walks on the beach..." forKey:@"description"];

[branch getShortUrlWithParams:params andCallback:^(NSString *url) {
	// show the link to the user or share it immediately	
}];

// or
// get a url with a tag for analytics in the dashboard
// example tag could be "fb", "email", "twitter"

[branch getShortUrlWithTag:@"twitter" andCallback:^(NSString *url) {
	// show the link to the user or share it immediately
}];

// or

[branch getShortUrlWithParams:params andTag:@"twitter" andCallback:^(NSString *url) {
	// show the link to the user or share it immediately
}];
```

#### Long links (immediate return but no shortening done)

Generating long links are immediate return, but can be long as the associated parameters are base64 encoded into the url itself.

```objc
// get a simple url to track events with
Branch *branch = [Branch getInstance];
String *urlToShare = [branch getLongURL];
```

### Referral system rewarding functionality

In a standard referral system, you have 2 parties: the original user and the invitee. Our system is flexible enough to handle rewards for all users. Here are a couple example scenarios:
1) Reward the original user for taking action (eg. inviting, purchasing, etc)
2) Reward the invitee for installing the app from the original user's referral link
3) Reward the original user when the invitee takes action (eg. give the original user credit when their the invitee buys something)

```objc
Branch *branch = [Branch getInstance];
[branch loadReferralStateWithCallback:^(BOOL changed) {
	// changed will indicate if there was a state change from before
	
	// get the number of installs attributed to the user
	NSInteger balance = [branch getBalance:@"install"];

	// reward the user
}];


// adds two credits towards the outstanding balance
// this will reduce the number returned by getBalance:@"install" by 2
[branch creditUserForReferralAction:@"install" withCredits:2];

```
