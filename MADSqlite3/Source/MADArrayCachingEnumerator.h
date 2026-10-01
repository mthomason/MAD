//
//  MADArrayCachingEnumerator.h
//  MADSqlite3
//
//  Created by Michael on 5/8/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#ifndef MADSqite3_MADArrayCachingEnumerator_h
#define MADSqite3_MADArrayCachingEnumerator_h

#import <Foundation/NSEnumerator.h>
#import <Foundation/NSURL.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADArrayCachingEnumerator : NSEnumerator
<NSFastEnumeration>

	- (instancetype)initWithURL:(NSURL *)url;
	@property (nonatomic, retain) NSURL *url;

@end

NS_ASSUME_NONNULL_END

#endif
