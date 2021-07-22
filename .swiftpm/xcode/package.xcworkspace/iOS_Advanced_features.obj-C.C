## iOS Advanced Features
SUGGEST EDITS
Create Content Reference
The Branch Universal Object encapsulates the thing you want to share.

Uses Universal Object properties

Swift
Objective-C

let buo = BranchUniversalObject.init(canonicalIdentifier: "content/12345")
buo.title = "My Content Title"
buo.contentDescription = "My Content Description"
buo.imageUrl = "https://lorempixel.com/400/400"
buo.publiclyIndex = true
buo.locallyIndex = true
buo.contentMetadata.customMetadata["key1"] = "value1"
Creating dynamic links without the share sheet
If you've built your own share sheet and you want to just create a Branch link for an individual share message or have another use case, you can create deep links directly with the following call:

Objective-C
Swift

[branchUniversalObject getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString *url, NSError *error) {
        if (!error) {
            NSLog(@"got my Branch invite link to share: %@", url);
        }
    }];
You can find examples of linkProperties above. You would next use the returned link and help the user post it to (in this example) Facebook.

Specifying a shared email subject
The majority of share options only include one string of text, except email, which has a subject and a body. The share text will fill in the body and you can specify the email subject in the link properties as shown below.

Objective-C
Swift

BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = @"share";
    linkProperties.channel = @"facebook";
    [linkProperties addControlParam:@"$email_subject" withValue:@"Your Awesome Deal"];
Create Link Reference
Generates the analytical properties for the deep link

Used for Create deep link and Share deep link

Uses Configure link data and custom data

Swift
Objective-C

let lp: BranchLinkProperties = BranchLinkProperties()
lp.channel = "facebook"
lp.feature = "sharing"
lp.campaign = "content 123 launch"
lp.stage = "new user"
lp.tags = ["one", "two", "three"]

lp.addControlParam("$desktop_url", withValue: "http://example.com/desktop")
lp.addControlParam("$ios_url", withValue: "http://example.com/ios")
lp.addControlParam("$ipad_url", withValue: "http://example.com/ios")
lp.addControlParam("$android_url", withValue: "http://example.com/android")
lp.addControlParam("$match_duration", withValue: "2000")

lp.addControlParam("custom_data", withValue: "yes")
lp.addControlParam("look_at", withValue: "this")
lp.addControlParam("nav_to", withValue: "over here")
lp.addControlParam("random", withValue: UUID.init().uuidString)
Create Deep Link
Generates a deep link within your app

Needs a Create content reference

Needs a Create link reference

Validate with the Branch Dashboard

Swift
Objective-C

buo.getShortUrl(with: lp) { url, error in
        print(url ?? "")
    }
Share Deep Link
Will generate a Branch deep link and tag it with the channel the user selects

Needs a Create content reference

Needs a Create link reference

Uses Deep Link Properties

Swift
Objective-C

let message = "Check out this link"
buo.showShareSheet(with: lp, andShareText: message, from: self) { (activityType, completed) in
  print(activityType ?? "")
}
Read Deep Link
Retrieve Branch data from a deep link

Best practice to receive data from the listener (to prevent a race condition)

Returns deep link properties

Swift
Objective-C

// listener (within AppDelegate didFinishLaunchingWithOptions)
Branch.getInstance().initSession(launchOptions: launchOptions) { params, error in
  print(params as? [String: AnyObject] ?? {})
}

// latest
let sessionParams = Branch.getInstance().getLatestReferringParams()

// first
let installParams = Branch.getInstance().getFirstReferringParams()
Navigate to Content
Handled within Branch.initSession()
Swift
Objective-C

// within AppDelegate application.didFinishLaunchingWithOptions
Branch.getInstance().initSession(launchOptions: launchOptions) { params , error in
  // Option 1: read deep link data
  guard let data = params as? [String: AnyObject] else { return }

  // Option 2: save deep link data to global model
  SomeCustomClass.sharedInstance.branchData = data

  // Option 3: display data
  let alert = UIAlertController(title: "Deep link data", message: "\(data)", preferredStyle: .alert)
  alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
  self.window?.rootViewController?.present(alert, animated: true, completion: nil)

  // Option 4: navigate to view controller
  guard let options = data["nav_to"] as? String else { return }
  switch options {
      case "landing_page": self.window?.rootViewController?.present( SecondViewController(), animated: true, completion: nil)
      case "tutorial": self.window?.rootViewController?.present( SecondViewController(), animated: true, completion: nil)
      case "content": self.window?.rootViewController?.present( SecondViewController(), animated: true, completion: nil)
      default: break
  }
}
Display
List content on iOS Spotlight

Needs a Create content reference

Swift
Objective-C

buo.automaticallyListOnSpotlight = true
Track ATT Opt-In and Opt-Out
Track when the responds to sharing their device data through Apple's AppTrackingTransparency framework
Implement from inside requestTrackingAuthorization(completionHandler:)
Swift
Objective-C

if (ATTrackingManager.trackingAuthorizationStatus == .notDetermined) {
    ATTrackingManager.requestTrackingAuthorization { (status) in
        Branch.getInstance().handleATTAuthorizationStatus(status.rawValue)
    }
}
Track content
Track how many times a piece of content is viewed

Needs a Create content reference

Validate with the Branch Dashboard

Swift
Objective-C

BranchEvent.standardEvent(.viewItem, withContentItem: buo).logEvent()
Track Events
All events related to a customer purchasing are bucketed into a "Commerce" class of data items

All events related to users interacting with your in-app content are bucketed to a "Content" class of data items.

All events related to users progressing in your app are bucketed to a "Lifecycle" class of data items.

To track custom events - not found in the table below - please see Track Custom Events

Validate with the Branch Dashboard

Use the table below to quickly find the event you want to track.

Event Name	Event Category	iOS
Add To Cart	Commerce Event	BranchStandardEventAddToCart
Add To Wishlist	Commerce Event	BranchStandardEventAddToWishlist
View Cart	Commerce Event	BranchStandardEventViewCart
Initiate Purchase	Commerce Event	BranchStandardEventInitiatePurchase
Add Payment Info	Commerce Event	BranchStandardEventAddPaymentInfo
Purchase	Commerce Event	BranchStandardEventPurchase
Spend Credits	Commerce Event	BranchStandardEventSpendCredits
Search	Content Event	BranchStandardEventSearch
View Item	Content Event	BranchStandardEventViewItem
View Items	Content Event	BranchStandardEventViewItems
Rate	Content Event	BranchStandardEventRate
Share	Content Event	BranchStandardEventShare
Complete Registration	Lifecycle Event	BranchStandardEventCompleteRegistration
Complete Tutorial	Lifecycle Event	BranchStandardEventCompleteTutorial
Achieve Level	Lifecycle Event	BranchStandardEventAchieveLevel
Unlock Achievement	Lifecycle Event	BranchStandardEventUnlockAchievement
Handle Branch Links when using Branch & Firebase SDK
There is a known issue with Firebase where it will call the following Instance Methods:

openURL
continueUserActivity
To account for this, you must check the link first to determine if it should be handled by the Branch SDK:

Swift 4.2

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
  //check for link_click_id
  if url.absoluteString.contains("link_click_id") == true{
    return Branch.getInstance().application(app, open: url, options: options)
  }
}

func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
  //check for app.link or appropriate Branch custom domain
  if userActivity.webPageURL?.absoluteString.contains("app.link"){
    return Branch.getInstance().continue(userActivity)
  }
}
Handle Push Notifications
Allows you to track Branch deep links in your push notifications

Include the Branch push notification handler in Initialize Branch

Add a Branch deep link in your push notification payload

Replace https://example.app.link/u3fzDwyyjF with your deep link
JSON

{
  "aps": {
    "alert": "Push notification with a Branch deep link",
    "badge": "1"
  },
  "branch": "https://example.app.link/u3fzDwyyjF"
}
Read deep link data from initSession Initialize Branch
Handle Links in Your Own App
Allows you to deep link into your own from your app itself
Swift
Objective-C

Branch.getInstance().handleDeepLink(withNewSession: URL(string: "https://example.app.link/u3fzDwyyjF"))
❗️
Handling a new deep link in your app

Handling a new deep link in your app will clear the current session data and a new referred "open" will be attributed.

Delay Branch Initialization
Delay the Branch initialization on Installs in order to request tracking permission from the user.

Create a boolean flag to represent an Install session and set it to true (e.g. firstOpen)
Before the Branch init in didFinishLaunchingWithOptions
a. if false continue with Branch SDK init
b. if true:
i. Persist launchOptions throughout onboarding flow or store locally when firstOpen is true
ii. Continue with onboarding flow
After determining User's tracking preference
a. Set tracking in Branch SDK per User's preference
b. Initilialize the Branch SDK utilizing the persisted launchOptions
Set Install boolean (firstOpen) to false
Track Apple Search Ads
Allows Branch to track Apple Search Ads deep linking analytics

Analytics from Apple's API have been slow which will make our analytics lower. Additionally, Apple's API does not send us all the data of an ad every time which will make ads tracked by us to show a generic campaign sometimes.

Add before initSession Initialize Branch

Swift
Objective-C

Branch.getInstance().delayInitToCheckForSearchAds()
Enable 100% Matching
Use the SFSafariViewController to increase the attribution matching success

The 100% match is a bit of a misnomer, as it is only 100% match from when a user clicks from the Safari browser. According to our analysis, clicking through Safari happens about 50-75% of the time depending on the use case. For example, clicking from Facebook, Gmail or Chrome won’t trigger a 100% match here. However, it’s still beneficial to the matching accuracy, so we recommend employing it.

When using a custom domain, add a branch_app_domain string key in your Info.plist with your custom domain
to enable 100% matching.

By default, cookie-based matching is enabled on iOS 9 and 10 if the SafariServices.framework
is included in an app's dependencies, and the app uses an app.link subdomain or sets the branch_app_domain
in the Info.plist. It can be disabled with a call to the SDK.

Add before initSession Initialize Branch

Swift
Objective-C

Branch.getInstance().disableCookieBasedMatching()
Enable / Disable User Tracking
If you need to comply with a user's request to not be tracked for GDPR purposes, or otherwise determine that a user should not be tracked, utilize this field to prevent Branch from sending network requests. This setting can also be enabled across all users for a particular link, or across your Branch links.

Swift
Objective-C

Branch.setTrackingDisabled(true)
You can choose to call this throughout the lifecycle of the app. Once called, network requests will not be sent from the SDKs. Link generation will continue to work, but will not contain identifying information about the user. In addition, deep linking will continue to work, but will not track analytics for the user.

Share to Email Options
Change the way your deep links behave when shared to email

Needs a Share deep link

Swift
Objective-C

lp.addControlParam("$email_subject", withValue: "Your Awesome Deal")
lp.addControlParam("$email_html_header", withValue: "<style>your awesome CSS</style>\nOr Dear Friend,")
lp.addControlParam("$email_html_footer", withValue: "Thanks!")
lp.addControlParam("$email_html_link_text", withValue: "Tap here")
Share Message Dynamically
Change the message you share based on the source the users chooses

Needs a Share deep link

Swift
Objective-C

// import delegate
class ViewController: UITableViewController, BranchShareLinkDelegate

func branchShareLinkWillShare(_ shareLink: BranchShareLink) {
  // choose shareSheet.activityType
  shareLink.shareText = "\(shareLink.linkProperties.channel)"
}
Return YES to continueUserActivity
When users enter your app via a Universal Link, we check to see to see if the link URL contains app.link. If so, Branch.getInstance().continue(userActivity) will return YES. If not, Branch.getInstance().continue(userActivity) will return NO. This allows us to explicitly confirm the incoming link is from Branch without making a server call.

For most implementations this will never be an issue, since your deep links will be routed correctly either way. However, if you use a custom link domain and you rely on Branch.getInstance().continue(userActivity) to return YES for every incoming Branch-generated Universal Link, you can inform the Branch SDK by following these steps:

In your Info.plist file, create a new key called branch_universal_link_domains.
Add your custom domain(s) as a string. image
Save the file.
📘
Multiple custom domains

If you have an unusual situation with multiple custom link domains, you may also configure branch_universal_link_domains as an array of strings. image

Handle links for web-only content
🚧
Universal Email Only

If you have links to content that exists only on web, and not in the app (for example, a temporary marketing webpage that isn't in the app) then this code snippet will ensure all links that have not had the deep linking script applied will open in a browser.

You should add this code snippet inside the deep link handler code block. Note that this uses query parameter $web_only=true. This should match the query parameter on the web URL you enter in the email.

Objective-C
Swift

[branch initSessionWithLaunchOptions:launchOptions andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
  // params are the deep linked params associated with the link that the user clicked before showing up.
  if (params[@"$3p"] && params[@"$web_only"]) {
            NSURL *url = [NSURL URLWithString:params[@"$original_url"]];
            if (url) {
                [application openURL:url]; // check to make sure your existing deep linking logic, if any, is not executed, perhaps by returning early
            }
  } else {
    // it is a deep link
    GDLog(@"branch deep link: %@", [params description]);
    [self handleBranchDeeplink:params];
  }
}];
Universal Links with Web-Only Content
Web-only Branch links that redirect to a site that hosts its own AASA file where Universal Links (UL) is enabled will cause unexpected behavior. Since Branch does not have a way to bypass UL (via JavaScript, delays, etc.), you must add a query param exclusion in the AASA file to persist web-only behavior when redirecting to a website. This only applies if you are trying to redirect via $web_only=true to their own website.

Add the following filter to the AASA File:

JSON

{
  "/": "*",
  "?": { "$web_only": "true" },
  "exclude": true,
  "comment": "Matches any URL which has a query item with name '$web_only' and a value of exactly true"
}
Now if $web_only=true is appended to the final fallback URL / redirect, iOS will not attempt to launch the App even if it is installed. ex. https://myhomepage.com/?$web_only=true
This link with the query parameter can now be used as the fallback of a web-only Branch link and persist the behavior all the way to myhomepage.com.

Set initialization metadata
🚧
Data Integration Only

If you are using a 3rd Party Data Integration Partner that requires setting certain identifiers before initializing the Branch SDK, you should add this code snippet:

Objective-C

//Inside *didFinishLaunchingWithOptions*
[[Branch getInstance] setRequestMetadataKey:@"{ANALYTICS_ID}" value: […]];
Replace {ANALYTICS_ID} with your Data Integration Partner's key.

App Clips
👍
App Clip Analytics

We will automatically attribute App Clip touches (like a QR Code scan) and sessions.
Touch:

Event Name: Click
last_attributed_touch_data_tilde_customer_placement: APP_CLIP
last_attributed_touch_data_tilde_creative_name: Set as $app_clip_id value if it is present in the App Clip link.
Session:

Event Name: Install/Open
user_data_environment: APP_CLIP
last_attributed_touch_data_tilde_creative_name: Set as $app_clip_id value if it is present.
An App Clip is a lightweight version of your app that offers users some of its functionality when and where they need it.

Follow Apple's developer documentation on creating an App Clip with Xcode

Important thing to note:

The Associated Domains entitlement has a new appclips type, which is required if you’re implementing app clips.
The AASA file must be updated to support app clips; via a Branch database update.
Please Submit a Ticket to make this request. Make sure to include your App Clip bundle ID and team ID in your request.
The Branch iOS SDK must be integrated into an App Clip in the same way as the Full App; with the following caveats:

You do not need the applinks setting in the App Clip's Associated Domains entitlement.
Cocoapods does not install the Branch SDK into your App Clip.
How to Persist App Clip Install Data to Subsequent Full App Install

Add an App Groups entitlement.
Choose a group will be used to share data between the App Clip and subsequent Full App install.

In both your Full App and App Clip, inform the Branch SDK of the App Group name prior to calling initSession. See Apple's developer doc for more information.
Objective-C
Swift

[[Branch getInstance] setAppClipAppGroup:@"group.io.branch"];
Branch Links as App Clip Invocation URLs
You can configure Branch links to be associated with App Clips. When creating a link, you specify which App Clip the Branch link should open. You do this via a Branch link parameter called $app_clip_id.

For example, let's say you have two App Clips, one for Stores and one for Products.

On the iTunesConnect Dashboard, you'd register the following two as advanced App Clip Experiences:

your.app.link/ac/s/* -- for Store links
your.app.link/ac/p/* -- for Product links
Then when creating a Branch link, you set $app_clip_id: s, as seen below:


Then Branch will automatically create a link with the App Clip ID as part of the path: https://your.app.link/ac/s/QfJ2H7c7jcb.

Additionally, you can specify an alias for these links. If you set $app_clip_url = s and alias to 12345, you'll get the following link: https://your.app.link/ac/s/12345. This would be a great way to create a link to Store with ID 12345!

Note that https://your.app.link/ac/s/12345 returns the same payload as https://your.app.link/12345. The path elements are only to ease registering App Clip experiences.

🚧
App Clip Code invocation URLs have a short character length limit

Unlike most App Clips, App Clip Code has a short URL limit. The length limit varies, but is about 35 characters. It is possible your Branch Link will be too long to be used in this situation. Use the shortest placement identifier possible to increase the odds your generated link will be short enough. We recommend specifying a short $app_clip_id and a short alias.

https://developer.apple.com/documentation/app_clips/creating_app_clip_codes

Invoking App Clips on iOS Channels
Once you have registered your Branch App Clip with Apple, Apple allows you to invoke App Clips on a few channels. Here's an example: https://branchster.app.link/6ZfIMUrDzbb#appclip

iMessage

Branch Links will automatically register and display your App Clip CTA on iMessage by default if they are registered as App Clip Invocation URLs.

Safari Banner

You can also display an App Clip banner on your website yourself. In order to do this, you need to add the standard Apple meta tag to your website:

HTML

<meta name="apple-itunes-app" content="app-id=myAppStoreID, app-clip-bundle-id=appClipBundleID>
If you want to display the banner on a Branch Deepview, add it to the HTML code in the Branch dashboard Deepview Manager.

For more information, please refer to Apple's documentation.

Include Apple's ATTrackingManager
🚧
Requires the inclusion of AdSupport Framework

In order for the ATTrackingManager to function, you must also ensure you've added the AdSupport framework in your iOS SDK implementation.

By default, the Branch SDK does not include the ATTrackingManager which is required by Apple if you want to collect the IDFA for attribution purposes.

Learn more about Apple's App Transparency Tracking Manager.

If you wish to use the IDFA, you will need to display the ATTrackingManager prompt at an appropriate time in your app flow. This sample code demonstrates displaying the prompt and logging the IDFA.

Swift
Objective-C

func requestIDFAPermission() {
        if #available(iOS 14, *) {
            DispatchQueue.main.async {
                ATTrackingManager.requestTrackingAuthorization { (status) in
                    if (status == .authorized) {
                        let idfa = ASIdentifierManager.shared().advertisingIdentifier
                        print("IDFA: " + idfa.uuidString)
                    } else {
                        print("Failed to get IDFA")
                    }
                }
            }
        }
    }
Starting from Branch iOS SDK 1.39.1, the SDK will see the authorization status if it is granted by the end-user. There is no additional work on your end to inform the Branch SDK.

On older versions of the SDK, the server infers the authorization status by the presence of the IDFA. Again there is no additional work on your end to inform the Branch SDK.

