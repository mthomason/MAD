//
//  MTViewPrintPageRenderReport.h
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTPrintPageRendererReport.h"

@interface MTViewPrintPageRenderReport : UIView

- (id)initWithFrame:(CGRect)frame pageNumber:(NSUInteger)pageNumber andPrintRenderData:(MTPrintPageRendererReport *)printRenderReport;

@end