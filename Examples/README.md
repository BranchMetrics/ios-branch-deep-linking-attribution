# Branch Examples

The Examples directory includes a few simple examples that demonstrate how to use some of the Branch
SDK's features.


## Bare Bones

This is a bare bones example of using Branch in a simple Swift project.

With this app you can create Branch deep links that have a 'secret' message associated with them.
You can send the link to your friend; when your friend clicks the link (or scans the QR code),
the app will open and reveal the message. If your friend doesn't have the app they'll be directed
to the app store to get the app, and because the link is a Branch deferred deep link, when they
open the app, the message will still appear.

The example code shows:

* How to use the Branch SDK in a simple Swift 4 application.
* How to respond to Branch NSNotification events.
* How to create and share Branch links in your app.
* How to create a QR code from a Branch link.


## WebViewExample

The WebViewExample displays the Wikipedia page for selected planets in a WKWebView.

The example code shows:

* How to use Branch links with a WKWebView.
* How to open Branch links programmatically.
* How to use Branch Universal Objects with app content.
* How to list your Branch Universal Object content in Spotlight search.
* How to share Branch links with a UIActivityViewController using the BranchShareLink helper.

