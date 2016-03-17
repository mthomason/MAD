//
//  MADKeyChainOperationGet.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADKeyChainOperationGet_h
#define MAD_Designer_MADKeyChainOperationGet_h

#import "MADOperation.h"

typedef NS_ENUM(short, MADKeyChainReadOperationTypes) {
    username,
    password
};

@protocol MADOperationResultStringProtocol <NSObject>

    - (NSString *)key;
    - (NSString *)result;
    - (bool)success;

@end

@interface MADKeyChainOperationGet : MADOperation
    <MADOperationResultStringProtocol>

    - (instancetype)initWithKey:(NSString *)key;
    @property (atomic, readonly, copy) NSString *result;
    @property (atomic, readonly, assign) bool success;
    @property (atomic, assign) MADKeyChainReadOperationTypes readOperationType;

@end

#endif
