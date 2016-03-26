//
//  MADErrorContainer.h
//  MAD
//
//  Created by Michael Thomason on 8/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
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

@end

#endif
