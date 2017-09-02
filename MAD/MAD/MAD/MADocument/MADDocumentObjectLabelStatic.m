//
//  MADDocumentObjectStaticLabel.m
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectLabelStatic.h"
#import <Foundation/NSString.h>
#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"
#import "RptqDocumentElementLabel.h"

@implementation MADDocumentObjectLabelStatic

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super initWithDefinition:definition]) {
        NSString *text = ((RptqDocumentElementLabel *)definition.item).text;;
        self.text = text.copy;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [super drawInRect:rect];
}

@end
