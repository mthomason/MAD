//
//  MTPair.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTObject.h"
#import "MTProtocolLog.h"

@interface MTPair : NSObject <MTProtocolLog>

@property (nonatomic, strong) id former;
@property (nonatomic, strong) id latter;

- (id)init;
- (id)initWithFormer:(id)former andLatter:(id)latter;
+ (id)pairWithFormer:(id)former andLatter:(id)latter;

- (id)initWithLeft:(id)left andRight:(id)right;
+ (id)pairWithLeft:(id)left andRight:(id)right;

- (id)left;
- (id)right;

@end