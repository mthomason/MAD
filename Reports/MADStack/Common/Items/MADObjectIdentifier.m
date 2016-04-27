//
//  MADDocumentObjectPickerType.m
//  MAD Designer
//
//  Created by Michael Thomason on 7/9/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADObjectIdentifier.h"
#import <Foundation/NSString.h>

@interface MADObjectIdentifier ()

    @property (nonatomic, copy, readwrite) NSString *identifier;
    @property (nonatomic, assign, readwrite) NSUInteger tag;

@end

@implementation MADObjectIdentifier

- (instancetype)initWithIdentifier:(NSString *)identifier andTag:(NSUInteger)tag {
    if (self = [super init]) {
        self->_identifier = identifier.copy;
        self->_tag = tag;
    }
    return self;
}

@end
