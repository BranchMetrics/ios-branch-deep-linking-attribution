//
//  TBTableData.h
//  Testbed-ObjC
//
//  Created by edward on 6/12/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TBTableItem : NSObject
@property (nonatomic, strong) NSString *title;
@end

@interface TBTableSection : TBTableItem
@end

@interface TBTableRow : TBTableItem
@property (nonatomic, strong) NSString *value;
@property (nonatomic, assign) SEL      selector;
@end

@interface TBTableData : NSObject
- (NSInteger) numberOfSections;
- (NSInteger) numberOfRowsInSection:(NSInteger)section;

- (void) addTableItem:(TBTableItem*)item;

- (TBTableSection*) sectionItemForSection:(NSInteger)section;
- (TBTableRow*) rowForIndexPath:(NSIndexPath*)indexPath;

- (TBTableSection*) addSectionWithTitle:(NSString*)title;
- (TBTableRow*) addRowWithTitle:(NSString*)title selector:(SEL)selector;
@end


