//
//  MADKeyChainOperationPut.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADKeyChainOperationPut_h
#define MAD_Designer_MADKeyChainOperationPut_h

#import "MADOperation.h"
#import "MADKeyChainKeyValueProtocol.h"

@interface MADKeyChainOperationPut : MADOperation

    - (instancetype)initWithKey:(NSString *)key description:(NSString *)description;

@end

#endif
