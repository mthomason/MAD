//
//  MTPair.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTObject.h"

@interface MTPair : NSObject


@property (retain) id former;
@property (retain) id latter;

- (id)init;
- (id)initWithFormer:(id)former andLatter:(id)latter;

+ (id)pairWithFormer:(id)former andLatter:(id)latter;

@end