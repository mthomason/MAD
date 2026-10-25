//
//  MADNotificationFileUpdate.h
//  MAD
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADNotificationFileUpdate_h
#define Reports_MADNotificationFileUpdate_h

#import <MAD/MADNotificationProtocol.h>
#import <Foundation/NSObject.h>

extern NSString * const MADNotificationIdentifierFileUpdate;

@interface MADNotificationFileUpdate : NSObject <MADNotificationProtocol>
- (instancetype)init  NS_UNAVAILABLE;
- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;
@end

#endif
