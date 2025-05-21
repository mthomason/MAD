//
//  MADDatabaseDataBinding.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADAPI_MADDatabaseDataBinding_h
#define MADAPI_MADDatabaseDataBinding_h

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADAliases.h>

#import <Foundation/NSObject.h>

@interface MADDatabaseDataBinding : NSObject

@property (nonatomic, strong, readonly) MADResult *value;
@property (nonatomic, assign, readonly) NSUInteger fieldIndex;
@property (nonatomic, assign, readonly) MADDataType datatype;
@property (nonatomic, readonly) NSUInteger columnNumber;

- (instancetype)initWithDataType: (MADDataType)datatype
					  fieldIndex: (NSUInteger)fieldIndex
						   value: (MADResult *)value NS_DESIGNATED_INITIALIZER;

@end

#endif
