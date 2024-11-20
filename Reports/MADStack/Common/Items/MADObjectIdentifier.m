//
//  MADDocumentObjectPickerType.m
//  MAD Designer
//
//  Created by Michael Thomason on 7/9/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADObjectIdentifier.h"
#import <Foundation/NSString.h>

@interface MADObjectIdentifier ()

    @property (nonatomic, copy, readwrite) NSString *identifier;
    @property (nonatomic, assign, readwrite) NSUInteger serial;

@end

@implementation MADObjectIdentifier

- (instancetype)initWithIdentifier:(NSString *)identifier andSerial:(NSUInteger)serial {
    if (self = [super init]) {
        _identifier = identifier.copy;
        _serial = serial;
    }
    return self;
}

@end
