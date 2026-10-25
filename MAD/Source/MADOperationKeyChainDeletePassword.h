//
//  MADOperationKeyChainDeletePassword.h
//  MAD Designer
//
//  Created by Michael on 8/12/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADOperationKeyChainDeletePassword_h
#define MAD_Designer_MADOperationKeyChainDeletePassword_h

#import <MADFoundation/MADOperation.h>

@interface MADOperationKeyChainDeletePassword : MADOperation

	- (instancetype)initWithKey:(NSString *)key;

	@property (nonatomic, readonly, copy) NSString *key;
	@property (atomic, readonly, assign) BOOL success;

@end

#endif
