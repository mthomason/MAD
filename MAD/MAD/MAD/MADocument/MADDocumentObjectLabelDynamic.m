//
//  MADDocumentObjectLabelDynamic.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectLabelDynamic.h"

#import <Foundation/NSString.h>
#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"

@implementation MADDocumentObjectLabelDynamic

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super initWithDefinition:definition]) {
        
        NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
        datasource = definition.datasource;
        
        NSString *text = [datasource getLabelDataDynamic:definition];
        self.text = text.copy;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [super drawInRect:rect];
}

@end
