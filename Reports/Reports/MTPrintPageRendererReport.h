//
//  MTPrintPageRendererReport.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RptqDocument+Extras.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqQuery+Extras.h"
#import "CGGeometry+Extras.h"

@interface MTPrintPageRendererReport : UIPrintPageRenderer

- (id)initWithDocument:(RptqDocument *)document;

@end