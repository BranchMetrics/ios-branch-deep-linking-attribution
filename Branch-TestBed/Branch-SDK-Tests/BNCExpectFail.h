//
//  BNCExpectFail.h
//  Branch-TestBed
//
//  Created by Jimmy Dee on 6/11/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#ifndef BNCExpectFail_h
#define BNCExpectFail_h

/*
 * XCTExpectFail introduced by Apple in Xcode 12.5 in 2021.
 * To be removed when Xcode 12.4 and earlier are gone.
 */
#ifndef XCTExpectFailure
#define XCTExpectFailure(_) XCTAssertTrue(YES); return;
#endif /* XCTExpectFail */

#endif /* BNCExpectFail_h */
