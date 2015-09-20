//
//  MTDatabaseDataBinding.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseProcessSqlServer_h
#define Reports_MTDatabaseProcessSqlServer_h

#import <Foundation/Foundation.h>
#import <MADFoundation/MTDataType.h>

@interface MTDatabaseDataBinding : NSObject

@property (nonatomic, strong, readonly) id value;
@property (nonatomic, assign, readonly) MTDataType datatype;
@property (nonatomic, assign, readonly) NSUInteger fieldIndex;

- (instancetype)initWithDataType: (MTDataType)datatype
                      fieldIndex: (NSInteger)fieldIndex
                           value: (id)value NS_DESIGNATED_INITIALIZER;

- (id)value;

@end

#endif
