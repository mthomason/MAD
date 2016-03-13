//
//  MTPair.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_DataStructures_MTPair_h
#define MAD_DataStructures_MTPair_h

#import <Foundation/NSObject.h>
#import "MTProtocolLog.h"

@interface MTPair : NSObject <NSCopying, MTProtocolLog>

@property (nonatomic, copy) id former;
@property (nonatomic, copy) id latter;

- (instancetype)init;
- (instancetype)initWithFormer:(id <NSCopying>)former andLatter:(id <NSCopying>)latter;
- (instancetype)initWithLeft:(id <NSCopying>)left andRight:(id <NSCopying>)right;

+ (instancetype)newPairWithFormer:(id <NSCopying>)former andLatter:(id <NSCopying>)latter;
+ (instancetype)newPairWithLeft:(id <NSCopying>)left andRight:(id <NSCopying>)right;

- (id)left;
- (id)right;

@end

#endif
