//
//  MTViewPrintPageRenderReport.h
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTReportViewerPrintPageRenderer.h"
#import "MTPrintingProtocol.h"


@interface MTReportViewerReportPageView : UIView

@property (nonatomic, assign) id <MTPrintingProtocol> delegate;
@property (nonatomic, assign) BOOL drawBlankPage;

@end
