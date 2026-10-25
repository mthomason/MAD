//
//  MADOperationKeyChainPut.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADOperationKeyChainPut_h
#define MAD_Designer_MADOperationKeyChainPut_h

#import <MADFoundation/MADOperation.h>
#import <MAD/MADKeyChainKeyValueProtocol.h>

@interface MADOperationKeyChainPut : MADOperation

- (instancetype)initWithKey:(NSString *)key description:(NSString *)description;

@end

#endif
