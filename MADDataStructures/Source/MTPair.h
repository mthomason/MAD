//
//  MTPair.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_DataStructures_MTPair_h
#define MAD_DataStructures_MTPair_h

#import <Foundation/NSObject.h>
#import <MADDataStructures/MTProtocolLog.h>

@interface MTPair : NSObject <NSCopying, MTProtocolLog>

	@property (nonatomic, strong) id former;
	@property (nonatomic, strong) id latter;

	- (instancetype)init;
	- (instancetype)initWithFormer:(id)former andLatter:(id)latter;
	- (instancetype)initWithLeft:(id)left andRight:(id)right;

	+ (instancetype)newPairWithFormer:(id)former andLatter:(id)latter;
	+ (instancetype)newPairWithLeft:(id)left andRight:(id)right;

	- (id)left;
	- (id)right;

@end

#endif
