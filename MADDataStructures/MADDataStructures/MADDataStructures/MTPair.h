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

@interface MTPair : NSObject
    <NSCopying, MTProtocolLog>

    @property (nonatomic, copy) NSObject <NSCopying> *former;
    @property (nonatomic, copy) NSObject <NSCopying> *latter;

    - (instancetype)init;
    - (instancetype)initWithFormer:(NSObject <NSCopying> *)former
                         andLatter:(NSObject <NSCopying> *)latter;
    - (instancetype)initWithLeft:(NSObject <NSCopying> *)left
                        andRight:(NSObject <NSCopying> *)right;

    + (instancetype)newPairWithFormer:(NSObject <NSCopying> *)former
                            andLatter:(NSObject <NSCopying> *)latter;
    + (instancetype)newPairWithLeft:(NSObject <NSCopying> *)left
                           andRight:(NSObject <NSCopying> *)right;

    - (NSObject <NSCopying> *)left;
    - (NSObject <NSCopying> *)right;

@end

#endif
