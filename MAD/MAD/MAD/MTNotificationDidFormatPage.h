//
//  MTNotificationDidFormatPage.h
//  MAD
//
//  Created by Michael Thomason on 7/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTNotificationDidFormatPage_h
#define Reports_MTNotificationDidFormatPage_h

#import <Foundation/NSObject.h>

extern NSString * const MTNotificationDidFormatPagesName;
extern NSString * const MTDatabaseNumberOfPagesFormattedKey;

@class MTReportFormatter;

@interface MTNotificationDidFormatPage : NSObject

+ (MTNotificationDidFormatPage *)sharedObject;
- (void)reportFormatter:(MTReportFormatter *)reportFormatter formattedPage:(NSUInteger)page;

@end

#endif
