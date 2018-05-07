//
//  TBTableData.h
//  Testbed-ObjC
//
//  Created by Edward Smith on 6/12/17.
//  Copyright © 2017 Branch. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, TBRowStyle) {
    TBRowStylePlain,
    TBRowStyleDisclosure,
    TBRowStyleSwitch
};

@interface TBTableItem : NSObject
@property (nonatomic, strong) NSString *title;
@end

@interface TBTableSection : TBTableItem
@end

@interface TBTableRow : TBTableItem
@property (nonatomic, strong) NSString      *value;
@property (nonatomic, assign) NSInteger     integerValue;
@property (nonatomic, assign) SEL           selector;
@property (nonatomic, assign) TBRowStyle    rowStyle;
@property (nonatomic, assign) NSInteger     userInfo;
@end

@interface TBTableData : NSObject
- (NSInteger) numberOfSections;
- (NSInteger) numberOfRowsInSection:(NSInteger)section;

- (void) addTableItem:(TBTableItem*)item;

- (TBTableSection*) sectionItemForSection:(NSInteger)section;
- (TBTableRow*) rowForIndexPath:(NSIndexPath*)indexPath;

- (TBTableSection*) addSectionWithTitle:(NSString*)title;
- (TBTableRow*) addRowWithTitle:(NSString*)title selector:(SEL)selector style:(TBRowStyle)style;

- (NSIndexPath*) indexPathForRow:(TBTableRow*)row;
- (UITableViewCell*) cellForTableView:(UITableView*)tableView tableRow:(TBTableRow*)tableRow;

- (void) updateTableView:(UITableView*)tableView row:(TBTableRow*)row;
- (TBTableRow*) rowForTableView:(UITableView*)tableView subView:(UIView*)view;
@end
