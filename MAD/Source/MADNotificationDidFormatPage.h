//
//  MADNotificationDidFormatPage.h
//  MAD
//
//  Created by Michael Thomason on 7/11/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADNotificationDidFormatPage_h
#define Reports_MADNotificationDidFormatPage_h

#import <Foundation/NSObject.h>

extern NSString * const MADNotificationDidFormatPagesName;
extern NSString * const MTDatabaseNumberOfPagesFormattedKey;

@class MADReportFormatter;

@interface MADNotificationDidFormatPage : NSObject

	+ (MADNotificationDidFormatPage *)sharedObject;
	- (void)reportFormatter:(MADReportFormatter *)reportFormatter
			  formattedPage:(NSUInteger)page;

@end

#endif
