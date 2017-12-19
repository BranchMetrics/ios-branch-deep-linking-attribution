//
//  ArrayPickerView.h
//  Branch-TestBed
//
//  Created by edward on 11/6/17.
//  Copyright © 2017 Branch, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ArrayPickerView : UIPickerView

@property (nonatomic, strong) NSString*_Nullable doneButtonTitle;

- (instancetype _Nonnull) initWithArray:(NSArray<NSString*> *_Nonnull)array;

- (void) presentFromViewController:(UIViewController*_Nonnull)viewController
                    withCompletion:(void (^_Nullable)(NSString*_Nullable result))completion;

@end
