//
//  MADNotification.h
//  MAD
//
//  Created by Michael on 10/19/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADNotificationProtocol_h
#define MAD_MADNotificationProtocol_h

#import <Foundation/NSObject.h>

@protocol MADNotificationProtocol <NSObject>

- (void)notify;

@end

#endif
