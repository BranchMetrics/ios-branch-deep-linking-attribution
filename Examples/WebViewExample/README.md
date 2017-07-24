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

## Setup with Fastlane

```bash
bundle install
bundle exec fastlane setup
```

The parameters used (keys, domains, etc.) are specified in `fastlane/Branchfile`.
Edit this file before running Fastlane in order to change to a different Branch
app.

## Building

Just run `pod install` to install all pod dependencies.
