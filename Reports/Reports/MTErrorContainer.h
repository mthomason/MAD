//
//  MTErrorContainer.h
//  MAD
//
//  Created by Michael Thomason on 8/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTErrorContainer : NSObject

- (void)addError:(NSError *)error;
- (NSString *)errorLog;
- (NSString *)errorLogCompact;
- (NSUInteger)count;

@end
