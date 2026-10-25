//
//  MADMock.h
//  MADTests
//
//  Created by Michael on 9/26/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <Foundation/NSObject.h>

NS_ASSUME_NONNULL_BEGIN

@class RptqDocument, MADDatabase;

@interface MADMock : NSObject

+ (RptqDocument *)createMockDocument;
+ (MADDatabase *)mockDatabase;

@end

NS_ASSUME_NONNULL_END
