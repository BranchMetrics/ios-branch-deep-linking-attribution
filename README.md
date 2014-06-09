## Installation

### Install library project

Download code from here (not yet live):
https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-SDK.zip

The testbed project (not working yet):
https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-SDK-TestBed.zip

### Initialize SDK (registers install/open events)

Called when app first initializes a session. Please add these lines to the splash view controller that will be seen on app install.

Also, if you want to track open events from the links, you can add these lines before view did load.

```objc
Branch *branch = [Branch getInstance:@"Your app key"];
[branch initUserSession];
```

#### OR

If you created a custom link with your own custom dictionary data, you probably want to know when the user session init finishes, so you need to register your view controllers as a BranchDelegate.

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
@end
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

#### Long links (immediate return but no shortening done)

There are a bunch of options for creating these links. You can tag them for analytics in the dashboard, or you can even pass data to the new installs or opens that come from the link click. How awesome is that?

```java
// get a simple url to track events with
Branch *branch = [Branch getInstance];
String *urlToShare = [branch getLongURL];

// get a url with a tag for analytics in the dashboard
// example tag could be "fb", "email", "twitter"
Branch *branch = [Branch getInstance];
String *urlToShare = [branch getLongURLWithTag:@"twitter"];

// associate data with a link
// you can access this data from anyone instance that installs or opens the app from this link (amazing...)
NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

[params setObject:"Joe" forKey:@"user"];
[params setObject:"https://s3-us-west-1.amazonaws.com/myapp/joes_pic.jpg" forKey:@"profile_pic"];
[params setObject:"Joe likes long walks on the beach..." forKey:@"description"];

Branch *branch = [Branch getInstance];
String urlToShare = [branch getLongURLWithParams:params];

// or
Branch *branch = [Branch getInstance];
String urlToShare = branch.getLongURLWithParams:params andTag:@"twitter"];

```

#### Short links (for social media sharing)

All of the above options are the same (ie tagging, data passing) but you need to pass a callback. This will be called when you link is prepared (which should return very quickly, ~ 100 ms to process)

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

### Get/reward event points

These functions will help you reward your users for sharing their links, and save the fact that you rewarded them to our server.


To get the number of install events that occurred from this user's links:

```objc
Branch *branch = [Branch getInstance];
[branch loadPointsWithCallback:^() {
	// get the number of installs attributed to the user
	NSInteger balance = [branch getBalance:@"install"];

	// reward the user
}];


// adds two credits towards the outstanding balance
// this will reduce the number returned by getBalance:@"install" by 2
[branch creditUserForReferralAction:@"install" withCredits:2];

```
