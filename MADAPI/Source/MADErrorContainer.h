//
//  MADErrorContainer.h
//  MAD
//
//  Created by Michael Thomason on 8/16/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADErrorContainer_h
#define MAD_MADErrorContainer_h

#import <Foundation/NSObject.h>

@interface MADErrorContainer : NSObject

- (void)addError:(NSError *)error;
- (NSString *)errorLog;
- (NSString *)errorLogCompact;
- (NSUInteger)count;
- (NSArray <__kindof NSError *> *)allObjects;
- (void)addErrorsFromContainer:(MADErrorContainer *)container;

@end

#endif
