//
//  MADDatabaseDataBinding.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDatabaseDataBinding_h
#define MAD_MADDatabaseDataBinding_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADDataType.h>

@interface MADDatabaseDataBinding : NSObject

    @property (nonatomic, strong, readonly) id value;
    @property (nonatomic, assign, readonly) MADDataType datatype;
    @property (nonatomic, assign, readonly) int fieldIndex;
    @property (nonatomic, assign, readonly) int columnNumber;

    - (instancetype)initWithDataType: (MADDataType)datatype
                          fieldIndex: (NSUInteger)fieldIndex
                               value: (id)value NS_DESIGNATED_INITIALIZER;

@end

#endif
