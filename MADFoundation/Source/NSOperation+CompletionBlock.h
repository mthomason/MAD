//
//  NSOperation+CompletionBlock.h
//  MADFoundation
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_NSOperation_CompletionBlock_h
#define MAD_Designer_NSOperation_CompletionBlock_h

#import <Foundation/NSOperation.h>
#import <Foundation/NSArray.h>

/*
	Small conveniences on NSOperation: a completion block that appends
	instead of replacing, and a bulk dependency adder.
 */
@interface NSOperation (CompletionBlock)

	- (void)addCompletionBlock:(void(^)(void))block;
	- (void)addDependencies:(NSArray <__kindof NSOperation *> *)dependencies;

@end

#endif
