//
//  NSOperation+Advanced.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 04.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#ifndef MAD_Designer_NSOperation_Advanced_h
#define MAD_Designer_NSOperation_Advanced_h

#import <Foundation/NSOperation.h>

@interface NSOperation (Advanced)

- (void)addCompletionBlock:(void(^)(void))block;
- (void)addDependencies:(NSArray /*NSOperation*/ *)dependencies;

@end

#endif
