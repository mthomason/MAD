//
//  MADNotificationDidFormatPage.h
//  MAD
//
//  Created by Michael Thomason on 7/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADNotificationDidFormatPage_h
#define Reports_MADNotificationDidFormatPage_h

#import <Foundation/NSObject.h>

extern NSString * const MADNotificationDidFormatPagesName;
extern NSString * const MTDatabaseNumberOfPagesFormattedKey;

@class MTReportFormatter;

@interface MADNotificationDidFormatPage : NSObject

+ (MADNotificationDidFormatPage *)sharedObject;
- (void)reportFormatter:(MTReportFormatter *)reportFormatter formattedPage:(NSUInteger)page;

@end

#endif
