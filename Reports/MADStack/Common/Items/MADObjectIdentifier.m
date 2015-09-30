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

@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, assign, readwrite) NSInteger tag;

@end

@implementation MADObjectIdentifier

- (instancetype)initWithIdentifier:(NSString *)identifier andTag:(NSInteger)tag {
    if (self = [super init]) {
        NSString *objid = [NSString stringWithString:identifier];
        self.identifier = objid;
        self.tag = tag;
    }
    return self;
}

@end
