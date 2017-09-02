//
//  MADPrintPageElementTextStatic.m
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADPrintPageElementTextStatic.h"
#import <Foundation/NSString.h>
#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"

@implementation MADPrintPageElementTextStatic

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceLabelStatic *)definition {
    if (self = [super initWithDefinition:definition]) {
        self.text = definition.text.copy;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [super drawInRect:rect];
}

@end
