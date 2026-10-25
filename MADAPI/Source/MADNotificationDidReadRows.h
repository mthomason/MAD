//
//  MADNotificationDidReadRows.h
//  MAD
//
//  Created by Michael Thomason on 6/12/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADNotificationDidReadRows_h
#define Reports_MADNotificationDidReadRows_h

#import <Foundation/NSObject.h>

extern NSString * const MADNotificationDidReadRowsName;
extern NSString * const MADDatabaseNumberOfRowsReadKey;

@class MADDatabase;

@interface MADNotificationDidReadRows : NSObject

	+ (MADNotificationDidReadRows *)sharedObject;
	- (void)database:(MADDatabase *)database readRow:(NSUInteger)row;

@end

#endif
