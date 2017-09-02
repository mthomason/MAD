//
//  MADPrintPageElementTextDynamic.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADPrintPageElementTextDynamic.h"

#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>

#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"

@implementation MADPrintPageElementTextDynamic

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceLabelDynamic *)definition {
    if (self = [super initWithDefinition:definition]) {
        
        NSString *text = @"";
        NSDictionary *rowData = nil;
        NSString *fieldKey = definition.fieldKey;
        NSError * __autoreleasing error = nil;
        rowData = [definition.datasource dataForRow: definition.detailRowId
                                             column: fieldKey
                                              error: &error];
        if (rowData != nil) {
            id value = rowData[fieldKey];
            text = [definition formattedStringForValue: value];
        }
        self.text = text.copy;
        
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    [super drawInRect:rect];
}

@end
