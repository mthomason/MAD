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

#ifndef NS_DESIGNATED_INITIALIZER
#if __has_attribute(objc_designated_initializer)
#define NS_DESIGNATED_INITIALIZER __attribute((objc_designated_initializer))
#else
#define NS_DESIGNATED_INITIALIZER
#endif
#endif

@interface MTPair : NSObject <MTProtocolLog>

@property (nonatomic, strong) id former;
@property (nonatomic, strong) id latter;

- (instancetype)init;
- (instancetype)initWithFormer:(id)former andLatter:(id)latter NS_DESIGNATED_INITIALIZER;
+ (instancetype)pairWithFormer:(id)former andLatter:(id)latter;

- (instancetype)initWithLeft:(id)left andRight:(id)right;
+ (instancetype)pairWithLeft:(id)left andRight:(id)right;

- (id)left;
- (id)right;

@end

#endif
