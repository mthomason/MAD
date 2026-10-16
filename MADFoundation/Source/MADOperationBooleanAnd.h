//
//  MADOperationBooleanAnd.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/21/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADOperationBooleanAnd_h
#define MAD_Designer_MADOperationBooleanAnd_h

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <MADFoundation/MADOperationCondition.h>

@interface MADOperationBooleanAnd : NSObject
    <MADOperationCondition>

- (instancetype)initWithConditions:(NSArray <NSObject <MADOperationCondition> *> *)conditions;

@end

#endif
