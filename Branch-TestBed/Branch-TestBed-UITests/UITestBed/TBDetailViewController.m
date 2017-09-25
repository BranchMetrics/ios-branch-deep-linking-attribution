//
//  TBDetailViewController.m
//  Testbed-ObjC
//
//  Created by Edward Smith on 6/19/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#import "TBDetailViewController.h"

@interface TBRowData : NSObject
@property NSString *key;
@property NSString *value;
@property NSInteger indentLevel;
+ (NSArray<TBRowData*>*) rowsFromDictionaryOrArray:(id<NSObject>)dictionaryOrArray;
@end

@implementation TBRowData

+ (NSArray<TBRowData*>*) rowsFromDictionaryOrArray:(id<NSObject>)dictionaryOrArray {
    return [self.class rowsFromDictionaryOrArray:(id<NSObject>)dictionaryOrArray withIndentLevel:0];
}

+ (NSArray<TBRowData*>*) rowsFromDictionaryOrArray:(id<NSObject>)dictionaryOrArray
                                   withIndentLevel:(NSInteger)indentLevel {

    NSMutableArray *array = [NSMutableArray new];
    if ([dictionaryOrArray isKindOfClass:[NSDictionary class]]) {

        NSDictionary *dictionary = (NSDictionary*)dictionaryOrArray;
        for (NSString *key in dictionary.keyEnumerator) {
            id<NSObject> value = dictionary[key];
            if ([value isKindOfClass:[NSDictionary class]] ||
                [value isKindOfClass:[NSArray class]]) {
                TBRowData *dr = [TBRowData new];
                dr.key = key;
                dr.value = @"";
                dr.indentLevel = indentLevel;
                [array addObject:dr];
                NSArray *a = [self.class rowsFromDictionaryOrArray:value withIndentLevel:indentLevel+1];
                if (a) [array addObjectsFromArray:a];
            } else
            if ([value isKindOfClass:[NSString class]]) {
                TBRowData *dr = [TBRowData new];
                dr.key = key;
                dr.value = (NSString*) value;
                dr.indentLevel = indentLevel;
                [array addObject:dr];
            } else
            if ([value respondsToSelector:@selector(stringValue)]) {
                TBRowData *dr = [TBRowData new];
                dr.key = key;
                dr.value = [(NSNumber*)value stringValue];
                dr.indentLevel = indentLevel;
                [array addObject:dr];
            } else {
                TBRowData *dr = [TBRowData new];
                dr.key = key;
                dr.value = NSStringFromClass(value.class);
                dr.indentLevel = indentLevel;
                [array addObject:dr];
            }
        }

    } else
    if ([dictionaryOrArray isKindOfClass:[NSArray class]]) {

        NSInteger index = -1;
        NSArray *valueArray = (NSArray*) dictionaryOrArray;
        for (id<NSObject>value in valueArray) {
            index++;
            NSString *key = [NSString stringWithFormat:@"[%ld]", (long) index];
            if ([value isKindOfClass:[NSDictionary class]] ||
                [value isKindOfClass:[NSArray class]]) {
                TBRowData *dr = [TBRowData new];
                dr.key = key;
                dr.value = @"";
                dr.indentLevel = indentLevel;
                [array addObject:dr];
                NSArray *a = [self.class rowsFromDictionaryOrArray:value withIndentLevel:indentLevel+1];
                if (a) [array addObjectsFromArray:a];
            } else
            if ([value isKindOfClass:[NSString class]]) {
                TBRowData *dr = [TBRowData new];
                dr.key = key;
                dr.value = (NSString*) value;
                dr.indentLevel = indentLevel;
                [array addObject:dr];
            } else
            if ([value respondsToSelector:@selector(stringValue)]) {
                TBRowData *dr = [TBRowData new];
                dr.key = key;
                dr.value = [(NSNumber*)value stringValue];
                dr.indentLevel = indentLevel;
                [array addObject:dr];
            } else {
                TBRowData *dr = [TBRowData new];
                dr.key = key;
                dr.value = NSStringFromClass(value.class);
                dr.indentLevel = indentLevel;
                [array addObject:dr];
            }
        }

    } else {

        TBRowData *dr = [TBRowData new];
        dr.key = NSStringFromClass(dictionaryOrArray.class);
        dr.indentLevel = indentLevel;
        [array addObject:dr];

    }

    return array;
}

@end

#pragma mark - TBDataViewController

@interface TBDetailViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSArray<TBRowData*> *dataRows;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@end

@implementation TBDetailViewController

- (instancetype) initWithData:(id<NSObject>)dictionaryOrArray {
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (!self) return self;
    _dictionaryOrArray = dictionaryOrArray;
    return self;
}

- (void) setDictionaryOrArray:(id<NSObject>)dictionaryOrArray {
    if (dictionaryOrArray != _dictionaryOrArray) {
        _dictionaryOrArray = dictionaryOrArray;
        _dataRows = nil;
        [self.tableView reloadData];
    }
}

- (void) setMessage:(NSString *)message {
    _message = message;
    [self.tableView reloadData];
}

- (NSArray<TBRowData*>*) dataRows {
    if (!_dataRows) {
        _dataRows = [TBRowData rowsFromDictionaryOrArray:_dictionaryOrArray];
    }
    return _dataRows;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView reloadData];
}

#pragma mark - Table View Delegates

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataRows.count;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.message.length)
        return self.message;
    else
    if (self.dataRows.count == 0)
        return @"No results to show";
    else
        return nil;
}

- (UITableViewCell*) tableView:(UITableView *)tableView
  cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *const kCellID = @"kCellID";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCellID];
    if (!cell)
        cell = [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellID];
    TBRowData *rowData = self.dataRows[indexPath.row];
    cell.textLabel.text = rowData.key;
    cell.detailTextLabel.text = rowData.value;
    cell.indentationLevel = rowData.indentLevel;
    return cell;
}

@end
