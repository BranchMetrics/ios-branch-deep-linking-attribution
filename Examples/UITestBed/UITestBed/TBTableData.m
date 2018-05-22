//
//  TBTableData.m
//  Testbed-ObjC
//
//  Created by Edward Smith on 6/12/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#import "TBTableData.h"

@implementation TBTableItem
@end

@implementation TBTableSection
@end

@implementation TBTableRow
@end

@interface TBTableData ()
@property (nonatomic, strong) NSMutableArray<TBTableSection*> *sections;
@property (nonatomic, strong) NSMutableArray<NSMutableArray<TBTableRow*>*> *rows;
@end

@implementation TBTableData

- (instancetype) init {
    self = [super init];
    if (!self) return self;
    self.sections = [NSMutableArray new];
    self.rows = [NSMutableArray new];
    return self;
}

- (NSInteger) numberOfSections {
    return self.sections.count;
}

- (NSInteger) numberOfRowsInSection:(NSInteger)section {
    return self.rows[section].count;
}

- (void) addTableItem:(TBTableItem*)item {
    if ([item isKindOfClass:[TBTableSection class]]) {
        [self.sections addObject:(TBTableSection*)item];
        [self.rows addObject:[NSMutableArray new]];
    } else
    if ([item isKindOfClass:[TBTableRow class]]) {
        [self.rows[self.sections.count-1] addObject:(TBTableRow*)item];
    }
    else {
        NSLog(@"Invalid table element: %@.", item);
    }
}

- (TBTableSection*) sectionItemForSection:(NSInteger)section {
    return self.sections[section];
}

- (TBTableRow*) rowForIndexPath:(NSIndexPath*)indexPath {
    return self.rows[indexPath.section][indexPath.row];
}

- (TBTableSection*) addSectionWithTitle:(NSString*)title {
    TBTableSection *s = [[TBTableSection alloc] init];
    s.title = title;
    [self addTableItem:s];
    return s;
}

- (TBTableRow*) addRowWithTitle:(NSString*)title selector:(SEL)selector style:(TBRowStyle)style {
    TBTableRow *r = [[TBTableRow alloc] init];
    r.title = title;
    r.selector = selector;
    r.rowStyle = style;
    [self addTableItem:r];
    return r;
}

- (NSIndexPath*) indexPathForRow:(TBTableRow*)rowToFind {
    NSInteger rowIndex = 0;
    NSInteger sectionIndex = 0;
    for (NSArray *sections in self.rows) {
        for (TBTableRow *row in sections) {
            if (row == rowToFind) {
                return [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
            }
            rowIndex++;
        }
        rowIndex = 0;
        sectionIndex++;
    }
    return nil;
}

- (UITableViewCell*) cellForTableView:(UITableView*)tableView tableRow:(TBTableRow*)tableRow {
    NSIndexPath *indexPath = [self indexPathForRow:tableRow];
    if (indexPath) return [tableView cellForRowAtIndexPath:indexPath];
    return nil;
}

- (void) updateTableView:(UITableView*)tableView row:(TBTableRow*)row {
    NSIndexPath*path = [self indexPathForRow:row];
    if (!path) return;
    [tableView reloadRowsAtIndexPaths:@[ path ] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (TBTableRow*) rowForTableView:(UITableView*)tableView subView:(UIView*)view {
    UITableViewCell *cell = (id) view;
    while (cell && ![cell isKindOfClass:[UITableViewCell class]]) {
        cell = (id) [cell superview];
    }
    if (!cell) return nil;
    NSIndexPath*path = [tableView indexPathForCell:cell];
    if (!path) return nil;
    return [self rowForIndexPath:path];
}

@end
