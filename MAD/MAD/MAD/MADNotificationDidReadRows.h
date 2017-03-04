//
//  MADNotificationDidReadRows.h
//  MAD
//
//  Created by Michael Thomason on 6/12/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADNotificationDidReadRows_h
#define Reports_MADNotificationDidReadRows_h

#import <Foundation/NSObject.h>

extern NSString * const MADNotificationDidReadRowsName;
extern NSString * const MADDatabaseNumberOfRowsReadKey;

@class MTDatabase;

@interface MADNotificationDidReadRows : NSObject

    + (MADNotificationDidReadRows *)sharedObject;
    - (void)database:(MTDatabase *)database readRow:(NSUInteger)row;

@end

#endif
