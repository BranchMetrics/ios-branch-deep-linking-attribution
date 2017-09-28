# WebViewExample

This app presents a list of the planets in a UITableView. When each
row is tapped, a custom ArticleView is displayed using the a UINavigationController.

The ArticleView contains a WKWebView and displays the Wikipedia page for the
selected planet. The ArticleViewController creates a Branch Universal Object in
`viewDidLoad` and registers a view event. A large Share button at the
bottom of the ArticleView calls `showShareSheet` on the BUO.

In the app delegate, the `Branch.getInstance().initSession()` callback routes
inbound links and pushes an ArticleViewController for the appropriate article when
a link is opened.

## Building

* Just run `pod install` and `pod update` in terminal to install all pod dependencies.
* Then build and run the WebViewExample.xcworkspace with Xcode.
