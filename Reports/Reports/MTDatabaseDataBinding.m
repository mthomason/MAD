//
//  MTDatabaseDataBinding.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseDataBinding.h"
#import "MTDatabaseField.h"

@interface MTDatabaseDataBinding ()

@property (nonatomic, strong) id value;
@property (nonatomic, assign) MTDataType datatype;
@property (nonatomic, assign) NSUInteger fieldIndex;

@end

@implementation MTDatabaseDataBinding

- (id)initWithDataType:(MTDataType)datatype fieldIndex:(NSInteger)fieldIndex value:(id)value {
    self = [super init];
    if (self) {
        [self setDatatype:datatype];
        [self setFieldIndex:fieldIndex];
        [self setValue:value];
    }
    return self;
}

- (MTDataType)datatype {
    return [self datatype];
}
- (NSUInteger)fieldIndex {
    return [self fieldIndex];
}
- (id)value {
    return [self value];
}

@end
