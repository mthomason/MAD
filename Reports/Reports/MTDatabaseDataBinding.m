//
//  MTDatabaseDataBinding.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseDataBinding.h"
#import "MTDatabaseField.h"

@interface MTDatabaseDataBinding ()

@property (nonatomic, strong, readwrite) id value;
@property (nonatomic, assign, readwrite) MTDataType datatype;
@property (nonatomic, assign, readwrite) NSUInteger fieldIndex;

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

@end
