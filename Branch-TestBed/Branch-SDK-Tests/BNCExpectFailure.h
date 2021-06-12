//
//  BNCExpectFailure.h
//  Branch-TestBed
//
//  Created by Jimmy Dee on 6/11/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#ifndef BNCExpectFailure_h
#define BNCExpectFailure_h

#include <Foundation/Foundation.h>

/*
 * XCTExpectFailure introduced by Apple in Xcode 12.5 in 2021.
 * This is to be removed once Xcode 12.4 and older are gone.
 * This is a function. It's easiest to check for the underlying
 * implementation class.
 */

/*
 * Indicates an assertion is expected to fail.
 * In Xcode 12.4 and older, short-circuits the rest of the test.
 */
#define BNCExpectFailure(m) \
    if (NSClassFromString(@"XCTExpectedFailure")) { \
        XCTExpectFailure(m); \
    } else { \
        XCTAssertTrue(true); \
        return; \
    }

/*
 * Indicates an assertion is expected to fail.
 * In Xcode 12.4 and older, short-circuits the rest of the test
 * and marks the expectation object passed as the second argument
 * fulfilled.
 */
#define BNCExpectFailureWithExpectation(m, e) \
    if (NSClassFromString(@"XCTExpectedFailure")) { \
        XCTExpectFailure(m); \
    } else { \
        XCTAssertTrue(true); \
        [e fulfill]; \
        return; \
    }

#endif /* BNCExpectFailure_h */
