//
//  MADPrintPageElementImage.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPrintPageElementImage.h"
#import <UIKit/UIImage.h>

#import "MADDocumentObjectReference.h"

@interface MADPrintPageElementImage ()
    @property (nonatomic, strong) UIImage *image;
@end

@implementation MADPrintPageElementImage

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
