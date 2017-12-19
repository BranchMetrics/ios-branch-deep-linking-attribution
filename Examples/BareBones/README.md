# Bare Bones Example

This is a bare bones example of using Branch in a simple Swift project.

With this app you can create Branch deep links that have a 'secret' message associated with them. You can send the link to your friend, and when your friend clicks the link (or scans the QR code), the app will open and reveal the message. If your friend doesn't have the app they'll be directed to the app store to get the app, and because the link is a Branch deferred deep link, when they open the app, the message will still appear.

The example code shows:

• How to use the Branch SDK in a simple Swift 4 application.

• How to create and share Branch links in your app.

• How to create a QR code from a Branch link.

• How to respond to Branch NSNotification events.


### Branch NSNotifications

When Branch has a deep link for your app to handle, it can pass the deep link to your app in several ways.

You can choose the way that is the most convenient and appropriate for your app.

To handle a Branch deep link, you can set a deep link handler block, or you can set a delegate on the shared Branch instance, or you can observe Branch NSNotifications posted on the default NSNotificationCenter.

The advantage of observing Branch NSNotifications is that it allows for more modularized code with greater separation of responsibility. Only those classes that care about Branch notifications need to know about them. This is particularly useful as your project grows larger and dependency management becomes an issue.

### Branch Notifications

#### **`BranchWillStartSessionNotification`**

This notification is sent just before the Branch SDK is about to determine if there is a deep link for your app to handle. This usually involves a server call so it may take some time for the SDK to make the determination.

##### Notification Keys

The notification `userInfo` dictionary may have these keys:

 Key | Value Type | Content
:---:|:----------:|:-------
`BranchURLKey` <br>(Optional) | NSURL | This is the URL if the Branch session was started with a URL.

#### **`BranchDidStartSessionNotification`**

This notification is sent when the Branch SDK has started a new URL session. There may or may not be a deep link for your app to handle. If there is, the `BranchUniversalObjectKey` value will have a BranchUniversalObject that contains the deep link content, and the `BranchLinkPropertiesKey` value will contain the link properties.

If an error has occurred the `BranchErrorKey` value will contain an `NSError` that describes the error.

##### Notification Keys

The notification `userInfo` dictionary may have these keys:

 Key | Value Type | Content
:---:|:----------:|:-------
`BranchURLKey`<br>(Optional) | NSURL | This is the URL that started the Branch session.
`BranchUniversalObjectKey`<br>(Optional) | BranchUniversalObject | If the Branch session has a Branch deep link for your app to handle, this is the deep link content decoded into a BranchUniversalObject.
`BranchLinkPropertiesKey`<br>(Optional) | BranchLinkProperties | If the Branch session has a Branch deep link for your app to handle, this is the deep link properties decoded into a BranchLinkProperties object.
`BranchErrorKey`<br>(Optional) | NSError | If an error occurred while starting the Branch session, this the NSError that describes the error.


## Building & Running the Code

Open the project in Xcode and choose "Product > Run" from the main menu in Xcode.
