//
//  MADDocumentObjectStaticLabel.m
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectLabelStatic.h"
#import <UIKit/NSStringDrawing.h>
#import "RptqDocumentElement.h"
#import "RptqDocumentElementLabel.h"
#import "MADElementStylizedText.h"
#import "MADDocumentObjectReference.h"

@implementation MADDocumentObjectLabelStatic

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super initWithDefinition:definition]) {
        self.text = ((RptqDocumentElementLabel *)definition.item).text.copy;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [super drawInRect:rect];
}

@end
