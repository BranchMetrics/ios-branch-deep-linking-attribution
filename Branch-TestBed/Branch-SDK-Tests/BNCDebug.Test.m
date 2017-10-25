

//--------------------------------------------------------------------------------------------------
//
//                                                                                   BNCDebug.Test.m
//                                                                                  Branch.framework
//
//                                                                                 Debugging Support
//                                                                        Edward Smith, October 2016
//
//                                             -©- Copyright © 2016 Branch, all rights reserved. -©-
//
//--------------------------------------------------------------------------------------------------


#import <XCTest/XCTest.h>
#import "BNCDebug.h"
#import "BNCTestCase.h"


#pragma mark Test DumpClass

@interface DumpClass : NSObject {
    NSString        *stringVar;
    int32_t         intVar;
    char            *charPtrVar;
    Class           classVar;
    float           floatVar;
    double          doubleVar;
    short           shortVar;
    BOOL            boolVar;
    unsigned char   ucharVar;
    unsigned int    uintVar;
    unsigned short  ushortVar;
    unsigned long   ulongVar;
    long double     doubleTroubleVar;

    struct UnhandledStruct {
        int int1;
        int int2;
    } UnhandledType;
}
@property (assign) int32_t  intProp;
@property (strong) NSString *stringProp;
@end


@implementation DumpClass

- (instancetype) init {
    char* s = "YopeCharString";
    char* cptr = malloc(strlen(s)+1);
    strcpy(cptr, s);

    self = [super init];
    if (!self) {
        free(cptr);
        return self;
    }
    stringVar = @"Yope!";
    intVar = 1;
    floatVar = 2.0;
    doubleVar = 3.0;
    charPtrVar = cptr;
    classVar = [NSNumber class];
    shortVar = 4;
    self.intProp = 5;
    self.stringProp = @"Props!";
    return self;
}

- (void) dealloc {
    if (charPtrVar) free(charPtrVar);
}

- (void) methodThatTakesAnNSString:(NSString*)string {
}

+ (void) classMethod {
    NSLog(@"Class method.");
}

@end

#pragma mark - BRDebugTest

@interface BRDebugTest : BNCTestCase
@end

@implementation BRDebugTest

- (void) testClassDump {

    NSString *truthString = [self stringFromBundleWithKey:@"DumpClassTest"];
    XCTAssertTrue(truthString, @"Can't load DumpClassTest resource from plist!");

    NSString *dumpString = BNCDebugStringFromObject(NSClassFromString(@"DumpClass"));
    NSLog(@"\nTruth:%@BNCSStringFromObjectDump result:%@", truthString, dumpString);

    NSMutableArray *truthArray =
        [NSMutableArray arrayWithArray:[truthString componentsSeparatedByString:@"\n"]];

    //  Remove the empty line and the address line:
    [truthArray removeObjectAtIndex:0];
    [truthArray removeObjectAtIndex:0];
    [truthArray sortUsingComparator:
    ^ NSComparisonResult(NSString *_Nonnull obj1, NSString *_Nonnull obj2) {
        return [obj1 compare:obj2];
    }];

    NSMutableArray *dumpArray =
        [NSMutableArray arrayWithArray:[dumpString componentsSeparatedByString:@"\n"]];
    [dumpArray removeObjectAtIndex:0];
    [dumpArray removeObjectAtIndex:0];
    [dumpArray sortUsingComparator:
    ^ NSComparisonResult(NSString *_Nonnull obj1, NSString *_Nonnull obj2) {
        return [obj1 compare:obj2];
    }];

    XCTAssertTrue(truthArray.count == dumpArray.count);
    for (int i = 0; i < truthArray.count; ++i) {
        XCTAssertTrue([truthArray[i] isEqualToString:dumpArray[i]]);
    }
}

- (void) testInstanceDump {
    NSString *truthString = [self stringFromBundleWithKey:@"DumpInstanceTest"];
    XCTAssertTrue(truthString, @"Can't load DumpInstanceTest resource from plist!");

    DumpClass *testInstance = [DumpClass new];
    NSString *dumpString = BNCDebugStringFromObject(testInstance);
    NSLog(@"\nTruth:%@BNCSStringFromObjectDump result:%@", truthString, dumpString);

    NSMutableArray *truthArray =
        [NSMutableArray arrayWithArray:[truthString componentsSeparatedByString:@"\n"]];
    [truthArray removeObjectAtIndex:0];
    [truthArray removeObjectAtIndex:0];
    [truthArray sortUsingComparator:
    ^ NSComparisonResult(NSString *_Nonnull obj1, NSString *_Nonnull obj2) {
        return [obj1 compare:obj2];
    }];

    NSMutableArray *dumpArray =
        [NSMutableArray arrayWithArray:[dumpString componentsSeparatedByString:@"\n"]];
    [dumpArray removeObjectAtIndex:0];
    [dumpArray removeObjectAtIndex:0];
    [dumpArray sortUsingComparator:
    ^ NSComparisonResult(NSString *_Nonnull obj1, NSString *_Nonnull obj2) {
        return [obj1 compare:obj2];
    }];

    XCTAssertTrue(truthArray.count == dumpArray.count);
    for (int i = 0; i < truthArray.count; ++i) {
        XCTAssertTrue([truthArray[i] isEqualToString:dumpArray[i]]);
    }
}

- (void) testDebuggerIsAttached {
    if (BNCDebuggerIsAttached())
        NSLog(@"Debugger is attached!");
    else
        NSLog(@"Debugger is not attached.");
}

- (void) testClassInstanceDump {
    NSString *s = nil;
    DumpClass *testInstance = [DumpClass new];
    s = BNCDebugStringFromObject(testInstance);
    NSLog(@"%@\n\n\n", s);

    s = BNCDebugStringFromObject(testInstance.class);
    NSLog(@"%@\n\n\n", s);

    s = BNCDebugStringFromObject(nil);
    NSLog(@"%@\n\n\n", s);
    XCTAssertEqualObjects(s, @"Object is nil.\n");
}

- (void) testClassList {
    NSArray<NSString*> *names = BNCDebugArrayOfReqisteredClasses();
    //NSLog(@"Names:\n%@.", names);

    // Test that it returned more than 0 results and contains some well known classes:
    XCTAssert(names.count > 0);
    XCTAssert([names containsObject:@"NSString"]);
    XCTAssert([names containsObject:@"XCTestCase"]);
    XCTAssert([names containsObject:@"NSObject"]);
    XCTAssert([names containsObject:@"NSMutableOrderedSet"]);
}

- (void) testBreakpoint {
    // if (BNCDebuggerIsAttached()) {
    if (self.class.testBreakpoints) {
        BNCDebugBreakpoint();
    }
}

@end
