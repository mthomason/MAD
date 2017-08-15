//
//  MADKeyChainOperationGet.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADKeyChainOperationGet_h
#define MAD_Designer_MADKeyChainOperationGet_h

#import "MADOperation.h"
#import "MADOperationResultStringProtocol.h"

@interface MADOperationKeyChainGet : MADOperation
    <MADOperationResultStringProtocol>

    - (instancetype)initWithKey:(NSString *)key withDescription:(NSString *)description;

    @property (nonatomic, readonly, copy) NSString *key;
    @property (atomic, readonly, copy) NSString *value;
    @property (atomic, readonly, assign) BOOL success;
    @property (atomic, assign) MADKeyChainReadOperationTypes readOperationType;

@end

#endif
