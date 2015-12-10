//
//  UniversalObjectViewController.m
//  Branch-TestBed
//
//  Created by Derrick Staten on 10/22/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import "UniversalObjectViewController.h"
#import "BranchUniversalObject.h"

@interface UniversalObjectViewController ()
@property (nonatomic, strong) BranchUniversalObject *myContent;
@end

@implementation UniversalObjectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.canonicalIdentifierTextField addTarget:self
                                          action:@selector(textFieldChanged:)
                                forControlEvents:UIControlEventEditingChanged];
    [self.titleTextField addTarget:self
                            action:@selector(textFieldChanged:)
                  forControlEvents:UIControlEventEditingChanged];
    
    UITapGestureRecognizer *hideKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:hideKeyboard];
}

- (void)textFieldChanged:(UITextField *)textField {
    if (textField == self.canonicalIdentifierTextField) {
        self.myContent.canonicalIdentifier = self.canonicalIdentifierTextField.text;
    }
    else if (textField == self.titleTextField) {
        self.myContent.title = self.titleTextField.text;
    }
}

- (void)hideKeyboard {
    [self.shortUrlTextField resignFirstResponder];
    [self.canonicalIdentifierTextField resignFirstResponder];
    [self.titleTextField resignFirstResponder];
}

- (IBAction)cmdInitUniversalObject {
    if (!self.canonicalIdentifierTextField.text.length && !self.titleTextField.text.length) {
        //generate a unique ID
        self.canonicalIdentifierTextField.text = [NSString stringWithFormat:@"ID%u", arc4random_uniform(100000)];
    }
    
    self.myContent = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:self.canonicalIdentifierTextField.text];
    self.myContent.title = self.titleTextField.text;
    self.myContent.contentDescription = @"My awesome piece of content!";
    self.myContent.imageUrl = @"https://s3-us-west-1.amazonaws.com/branchhost/mosaic_og.png";
    
    [self.myContent addMetadataKey:@"foo" value:@"bar"];
    
    NSLog(@"You've initialized a %@", self.myContent);

    [self hideKeyboard];
}

- (void)ensureUniversalObjectIsInitialized {
    if (!self.myContent) {
        NSLog(@"Please `init universal object` first");
    }
}

- (IBAction)cmdRegisterView {
    [self ensureUniversalObjectIsInitialized];
    [self.myContent registerViewWithCallback:^(NSDictionary *params, NSError *error) {
        if (!error) {
            NSLog(@"success registering view!");
        }
        else {
            NSLog(@"error registering view: %@", error);
        }
    }];
}

- (BranchLinkProperties *)exampleLinkProperties {
    BranchLinkProperties *props = [[BranchLinkProperties alloc] init];
    props.tags = @[@"tag1", @"tag2"];
    props.feature = @"invite";
    props.channel = @"Twitter";
    props.stage = @"2";
    [props addControlParam:@"$desktop_url" withValue:@"http://example.com"];
    return props;
}

- (IBAction)cmdGetShortUrl {
    [self ensureUniversalObjectIsInitialized];
    [self.myContent getShortUrlWithLinkProperties:[self exampleLinkProperties] andCallback:^(NSString *url, NSError *error) {
        if (!error) {
            NSLog(@"success getting url! %@", url);
            self.shortUrlTextField.text = url;
        }
        else {
            NSLog(@"error getting url: %@", error);
        }
    }];
    
    /**
     Synchronous call (not recommended):
     
    [self.myContent getShortUrlWithLinkProperties:[self exampleLinkProperties]];
     */
}

- (IBAction)cmdListOnSpotlight {
    [self ensureUniversalObjectIsInitialized];
    [self.myContent listOnSpotlightWithCallback:^(NSString *url, NSError *error) {
        if (!error) {
            NSLog(@"success listing content on Spotlight Search! Look up your title!");
        }
        else {
            NSLog(@"error listing content on Spotlight Search: %@", error);
        }
    }];
    
    /**
     Simple Alternative:
     
    [self.myContent listOnSpotlight];
     */
}

- (IBAction)cmdShowShareSheet {
    [self ensureUniversalObjectIsInitialized];
    [self.myContent showShareSheetWithLinkProperties:[self exampleLinkProperties] andShareText:@"Super amazing thing I want to share!" fromViewController:self andCallback:^{
        NSLog(@"finished presenting");
    }];
    
    /**
     Simple alternative:
     
    [self.myContent showShareSheetWithShareText:@"Super amazing thing I want to share!" andCallback:nil];
     */
}

// This is the old share sheet method.
- (IBAction)cmdOldShareSheet {
    // Setup up the content you want to share, and the Branch
    // params and properties, as you would for any branch link
    
    // No need to set the channel, that is done automatically based
    // on the share activity the user selects
    NSString *shareString = @"Super amazing thing I want to share!";
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjects:@[@"test_object", @"here is another object!!", @"Kindred", @"https://s3-us-west-1.amazonaws.com/branchhost/mosaic_og.png"] forKeys:@[@"key1", @"key2", @"$og_title", @"$og_image_url"]];
    
    NSArray *tags = @[@"tag1", @"tag2"];
    
    NSString *feature = @"invite";
    
    NSString *stage = @"2";
    
    // Branch UIActivityItemProvider
    UIActivityItemProvider *itemProvider = [Branch getBranchActivityItemWithParams:params feature:feature stage:stage tags:tags];
    
    /**
     If you really love the itemProvider, here's a way to get one derived from a BranchUniversalObject:
     
    UIActivityItemProvider *itemProvider = [self.myContent getBranchActivityItemWithLinkProperties:[self exampleLinkProperties]];
     */
    
    // Pass this in the NSArray of ActivityItems when initializing a UIActivityViewController
    UIActivityViewController *shareViewController = [[UIActivityViewController alloc] initWithActivityItems:@[shareString, itemProvider] applicationActivities:nil];
    
    // Required for iPad/Universal apps on iOS 8+
    if ([shareViewController respondsToSelector:@selector(popoverPresentationController)]) {
        shareViewController.popoverPresentationController.sourceView = self.view;
    }

    // Present the share sheet!
    [self.navigationController presentViewController:shareViewController animated:YES completion:nil];
}

@end
