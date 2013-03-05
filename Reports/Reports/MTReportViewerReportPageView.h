//
//  MTViewPrintPageRenderReport.h
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTPrintPageRendererReport.h"
#import "MTPrintingProtocol.h"


@interface MTReportViewerReportPageView : UIView

- (id)initWithFrame:(CGRect)frame;

@property (assign, nonatomic) id <MTPrintingProtocol> delegate;

@end