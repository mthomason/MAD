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
#import "RptqDocumentElementImage.h"
#import "RptqDocumentElement.h"

@interface MADDocumentObjectImage ()
    @property (nonatomic, strong) UIImage *image;
@end

@implementation MADDocumentObjectImage

- (void)dealloc {
    _image = nil;
}

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super init]) {
        self.image = ((RptqDocumentElementImage *)definition.item).image.copy;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [self.image drawInRect:rect];
}

@end
