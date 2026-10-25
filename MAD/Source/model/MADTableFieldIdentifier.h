//
//  MADTableFieldIdentifier.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  A table id and a field id boxed as one value -- the endpoint type of
//  MADModelQueryLink.
//

#ifndef MAD_MADTableFieldIdentifier_h
#define MAD_MADTableFieldIdentifier_h

#import <Foundation/NSObject.h>
@interface MADTableFieldIdentifier : NSObject

- (instancetype)initWithTableID:(int64_t)tableID
					 andFieldID:(int64_t)fieldID NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (readonly, nonatomic, assign) int64_t tableID;
@property (readonly, nonatomic, assign) int64_t fieldID;

- (NSNumber *)tableObjectID;
- (NSNumber *)fieldObjectID;

@end

#endif /* MADTableFieldIdentifier_h */
