//
//  MADProgress.h
//  MAD
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADProgress_h
#define MAD_Designer_MADProgress_h

#import <Foundation/NSObject.h>

@interface MADProgress : NSObject <NSCopying>

	- (instancetype)initWithMessage:(NSString *)message andProgress:(float)progress;

	@property (readonly, nonatomic, copy) NSString *message;
	@property (readonly, nonatomic, assign) float progress;

@end

#endif
