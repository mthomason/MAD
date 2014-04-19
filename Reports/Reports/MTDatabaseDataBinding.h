//
//  MTDatabaseDataBinding.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTDatabaseField.h"

@interface MTDatabaseDataBinding : NSObject

- (id)initWithDataType:(MTDataType)datatype fieldIndex:(NSInteger)fieldIndex value:(id)value;

- (MTDataType)datatype;
- (NSUInteger)fieldIndex;
- (id)value;

@end
