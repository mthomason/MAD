//
//  MADDocumentObjectDataReferenceLabelStatic.m
//  MAD
//
//  Created by Michael on 5/18/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectDataReferenceLabelStatic.h"
#import "MADDocumentObjectDataReferenceBarcode.h"
#import "RptqDocumentElementLabel.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqDocumentElementBarcode+Extras.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaField.h"
#import "MADPrintPageRendererDataSource.h"
#import "madlog.h"

#import <MADAPI/MADDatabase.h>

@interface MADDocumentObjectDataReferenceLabelStatic ()

@property (nonatomic, readonly) RptqDocumentElementLabel *item;

@end

@implementation MADDocumentObjectDataReferenceLabelStatic

@dynamic item;

- (NSString *)text {
	return self.item.text ?: @"";
}

@end
