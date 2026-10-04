//
//  MADAtomicStoreCacheNode.h
//  MAD
//
//  Created by Michael on 4/22/19.
//  Copyright © 2019 Michael Thomason. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADAtomicStoreCacheNode : NSAtomicStoreCacheNode {
	NSEntityDescription *entityDescription; // cached for convenience
	NSDictionary *propertyDataCache;
}

- (NSEntityDescription *)entity;

- (void)setPropertyCacheData:(NSDictionary *)dictionary;

- (bool)resolvePropertyValues:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
