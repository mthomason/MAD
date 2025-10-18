//
//  MADPrintPageElementTextDynamic.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPrintPageElementTextDynamic.h"
#import "MADDocumentObjectDataReference.h"
#import "MADDocumentObjectDataReferenceLabelDynamic.h"
#import "MADPrintPageRendererDataSource.h"

#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>

@implementation MADPrintPageElementTextDynamic

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceLabelDynamic *)definition {
	if (self = [super initWithDefinition:definition]) {
		
		NSString *fieldKey = definition.fieldKey;
		NSError * __autoreleasing error = nil;
		NSDictionary *rowData = [definition.datasource dataForRow: definition.detailRowId
														   column: fieldKey
															error: &error];
		NSString *text = @"";
		if (rowData != nil) {
			id value = rowData[fieldKey];
			text = [definition formattedStringForValue: value];
		}
		self.text = [text copy];
		
	}
	return self;
}

- (void)drawInRect:(CGRect)rect {
	[super drawInRect:rect];
}

@end
