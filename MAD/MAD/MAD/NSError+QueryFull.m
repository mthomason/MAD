//
//  NSError+QueryFull.m
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "NSError+QueryFull.h"

@implementation NSError (QueryFull)

+ (instancetype)newErrorQueryFullMissingFields {

    NSString *message = NSLocalizedString(@"Empty query while using \"only "
                                          @"active fields.\" You may need to reference "
                                          @"some query fields.",
                                          @"Empty query while using \"only active "
                                          @"fields.\" You may need to reference some "
                                          @"query fields.");
    NSDictionary *errorInfo;
    errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                message, NSLocalizedDescriptionKey, nil];
    
    NSError *error =  [[self alloc] initWithDomain: @"MADQuery"
                                              code: 5774
                                          userInfo: errorInfo];
    return error;
}

@end
