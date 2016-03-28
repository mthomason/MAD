//
//  MTDatabaseDataBinding.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTDatabaseDataBinding_h
#define MAD_MTDatabaseDataBinding_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADDataType.h>

@interface MTDatabaseDataBinding : NSObject

    @property (nonatomic, strong, readonly) id value;
    @property (nonatomic, assign, readonly) MTDataType datatype;
    @property (nonatomic, assign, readonly) int fieldIndex;
    @property (readonly) int columnNumber;

    - (instancetype)initWithDataType: (MTDataType)datatype
                          fieldIndex: (NSUInteger)fieldIndex
                               value: (id)value NS_DESIGNATED_INITIALIZER;

@end

#endif
