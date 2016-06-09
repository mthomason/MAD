//
//  MADDocumentObjectStaticLabel.m
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectLabelStatic.h"
#import <UIKit/NSStringDrawing.h>
#import "RptqDocumentObject.h"
#import "RptqDocumentObjectLabel.h"
#import "MADocumentObjectAttributesText.h"

@interface MADDocumentObjectLabelStatic ()

    @property (nonatomic, copy, readwrite) NSString *text;

@end

@implementation MADDocumentObjectLabelStatic

- (instancetype)initWithObject:(RptqDocumentObject *)object {
    if (self = [super initWithType:MTDocumentObjectTypeLabelStatic andObject:object]) {
        _text = object.isLabel.text.copy;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect
    withAttributes:(__kindof MADocumentObjectAttributesText *)attributes {
    [_text drawWithRect: rect
                options: NSStringDrawingUsesLineFragmentOrigin
             attributes: attributes.fontAttributes
                context: nil];
}

@end
