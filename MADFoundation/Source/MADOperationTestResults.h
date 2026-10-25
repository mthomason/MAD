//
//  MADOperationTestResults.h
//  MAD
//
//  Created by Michael on 8/17/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADOperationTestResults_h
#define MADOperationTestResults_h

#import <Foundation/NSObject.h>
#import <Foundation/NSError.h>

@protocol MADOperationTestResults <NSObject>

	@property (nonatomic, readonly, strong) NSError *error;
	@property (nonatomic, readonly, assign, getter=isSuccess) BOOL success;

@end

#endif /* MADOperationTestResults_h */
