//
//  MADDocumentObjectImage.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectImage.h"
#import <UIKit/UIImage.h>

#import "MADDocumentObjectReference.h"

@interface MADDocumentObjectImage ()
    @property (nonatomic, strong) UIImage *image;
@end

@implementation MADDocumentObjectImage

- (void)dealloc {
    _image = nil;
}

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceImage *)definition {
    if (self = [super init]) {
        self.image = definition.image;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [self.image drawInRect:rect];
}

@end
