//
//  MADOperationKeyChainPut.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationKeyChainPut_h
#define MAD_Designer_MADOperationKeyChainPut_h

#import <MADFoundation/MADOperation.h>
#import "MADKeyChainKeyValueProtocol.h"

@interface MADOperationKeyChainPut : MADOperation

    - (instancetype)initWithKey:(NSString *)key description:(NSString *)description;

@end

#endif
