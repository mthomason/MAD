//
//  MTActivityItemProviderPdf.m
//  MAD
//
//  Created by Michael Thomason on 2/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTActivityItemProviderPdf.h"
#import "MTReportViewerPrintPageRenderer.h"
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "MAReportDocument.h"
#import "MTQuery.h"
//#import "MTCache.h"
#import "MTReportFormatter.h"
#import "MTReportViewerPrintPageRenderer.h"

@implementation MTActivityItemProviderPdf

- (id)item {
    NSString *temporaryDirectoryPath = NSTemporaryDirectory();
    NSURL *temporaryDirectory = [NSURL fileURLWithPath: temporaryDirectoryPath];
    NSURL *temporaryFile = [[temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"] retain];

    MTApplicationInstance *app = [AppDelegate app];
    MAReportDocument *reportDocument = [app activeDocument];
    
    MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:[reportDocument reportFormatter]];
    [printPageRender writeToPdf:temporaryFile];
    [printPageRender release];
    return [temporaryFile autorelease];
}

@end
