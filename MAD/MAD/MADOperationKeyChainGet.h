//
//  MADOperationKeyChainGet.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADOperationKeyChainGet_h
#define MAD_Designer_MADOperationKeyChainGet_h

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationResultStringProtocol.h>

@interface MADOperationKeyChainGet : MADOperation <MADOperationResultStringProtocol>

- (instancetype)initWithKey:(NSString *)key withDescription:(NSString *)description NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, readonly, copy) NSString *key;
@property (atomic, readonly, copy) NSString *value;
@property (atomic, readonly, assign) BOOL success;
@property (atomic, assign) MADKeyChainReadOperationTypes readOperationType;

@end

#endif
