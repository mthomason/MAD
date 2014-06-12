//
//  MTNotificationDidReadRows.h
//  MAD
//
//  Created by Michael Thomason on 6/12/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTNotificationDidReadRows : NSObject

+ (MTNotificationDidReadRows *)sharedObject;
- (void)database:(id)database readRow:(NSUInteger)row;

@end
