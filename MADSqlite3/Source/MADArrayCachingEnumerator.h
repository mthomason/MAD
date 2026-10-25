//
//  MADArrayCachingEnumerator.h
//  MADSqlite3
//
//  Created by Michael on 5/8/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

/*
 
 This file currently is included in `MADSqlite3`, but the `.m` file has no target membership, meaning
 the header points to no code.  I believe this was related to `MADArrayCaching`; that is, I believe this is the
 fast enumerator for it, and I believe it is unfinished, but I'm not sure.  This should be investigated.
 
 */

#ifndef MADSqite3_MADArrayCachingEnumerator_h
#define MADSqite3_MADArrayCachingEnumerator_h

#import <Foundation/NSEnumerator.h>
#import <Foundation/NSURL.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADArrayCachingEnumerator : NSEnumerator <NSFastEnumeration>

	- (instancetype)initWithURL:(NSURL *)url;
	@property (nonatomic, retain) NSURL *url;

@end

NS_ASSUME_NONNULL_END

#endif
