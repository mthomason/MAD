//
//  MTActivityItemProviderPdf.m
//  MAD
//
//  Created by Michael Thomason on 2/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTActivityItemProviderPdf.h"
#import "MADocument.h"
#import "MTReportFormatter.h"
#import "MTReportViewerPrintPageRenderer.h"
#import "MTActivityIndicator.h"
#import "MTPaper.h"
#import "MTDataTable.h"
#import "MTNotificationDidFormatPage.h"
#import "UIDevice+Hack.h"

@interface  MTActivityItemProviderPdf ()

@property (nonatomic, weak, readwrite) UIActivityViewController *activityViewController;

@end

@implementation MTActivityItemProviderPdf

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
    id result = [super activityViewController:activityViewController itemForActivityType:activityType];
    [self setActivityViewController:activityViewController];
    return result;
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController dataTypeIdentifierForActivityType:(NSString *)activityType {
    [self setActivityViewController:activityViewController];
    return activityType == nil ? @"" : [super activityViewController:activityViewController dataTypeIdentifierForActivityType:activityType];
}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(NSString *)activityType suggestedSize:(CGSize)size {
    [self setActivityViewController:activityViewController];
    return [super activityViewController:activityViewController thumbnailImageForActivityType:activityType suggestedSize:size];
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    [self setActivityViewController:activityViewController];
    return [super activityViewControllerPlaceholderItem:activityViewController];
}

- (id)item {
    id item = nil;
    if ([[self activityType] caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {    //Printer
        if ([UIDevice isPad]) {
            [self.delegate showPrintDialog]; //Need some help getting out of this popover!!!
        }
        item = nil;
    } else {                                                                                    //Return URL to PDF printout.
        NSString *temporaryDirectoryPath = NSTemporaryDirectory();
        NSURL *temporaryDirectory = [NSURL fileURLWithPath: temporaryDirectoryPath];
        item = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
        
        [self writeToPdf:item withViewController:self.activityViewController];
    }
    return item;
}

- (void)writeToPdf:(NSURL *)filepath withViewController:(UIViewController *)window {
    [self disableUserInteraction:window.view];
    
    MTActivityIndicator *activityView = [[MTActivityIndicator alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 200.0000f)];
    activityView.center = window.view.center;
    
    [window.view performSelectorOnMainThread:@selector(addSubview:) withObject:activityView waitUntilDone:YES];
    [self.document setStatusLabel:activityView];
    
    __weak MADocument *weakdoc = self.document;
    
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(dipatchQueue, ^{
        
        
        NSDictionary *options = @{(NSString *)kCGPDFContextCreator :  @"MAD® Designer"};
        CGRect letterRect = [MTPaper rectLetter];
        [[weakdoc mainDataTable] sortUsingDescriptors:[weakdoc sortDescriptors]];
        MTReportFormatter *rf = [MTReportFormatter reportFormatterWithQuery:weakdoc.mainQuery
                                                                     layout:weakdoc.document
                                                                    options:MTReportFormatterOptionsMargin];
        [rf setCachedDelegate:weakdoc];
        [rf setDataDelegate:weakdoc];
        [rf setOverrideIdentifier:@"madpreview"];
        [rf setDidRefresh:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver: weakdoc
                                                 selector: @selector(reportFormatterDidFormatPage:)
                                                     name: MTNotificationDidFormatPagesName
                                                   object: rf];
        
        
        [rf setLayoutSize:letterRect.size];
        CGFloat halfInch = 72.0000f / 2.0000f;
        UIEdgeInsets border = UIEdgeInsetsMake(halfInch, halfInch, halfInch, halfInch);
        CGRect trimBoxRect = UIEdgeInsetsInsetRect(letterRect, border);
        [rf setMarginUsingPrintableRect:trimBoxRect];
        [rf setDatasource:weakdoc];
        [rf formatForSize:letterRect.size contentChanged:NO];
        
        
        [[NSNotificationCenter defaultCenter] removeObserver: weakdoc
                                                        name: MTNotificationDidFormatPagesName
                                                      object: rf];
        
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:rf
                                                                                                                  dataTable:[weakdoc mainDataTable]];
        NSUInteger numberOfPages = [rf numberOfPages];
        UIGraphicsBeginPDFContextToFile([filepath path], letterRect, options);
        
        NSValue *trimBox = [NSValue valueWithCGRect:trimBoxRect];
        NSDictionary *boxInfo = @{(__bridge NSString *)kCGPDFContextTrimBox: trimBox};
        NSString *numberOfPagesString = [NSNumberFormatter localizedStringFromNumber:@(numberOfPages) numberStyle:NSNumberFormatterDecimalStyle];
        for (NSUInteger i=0; i<numberOfPages; i++) {
            @autoreleasepool {
                UIGraphicsBeginPDFPageWithInfo(letterRect, boxInfo);
                [printPageRender drawPageAtIndex:i inRect:trimBoxRect];
                NSString *iString = [NSNumberFormatter localizedStringFromNumber:@(i) numberStyle:NSNumberFormatterDecimalStyle];
                NSString *text = [NSString stringWithFormat:@"Drawing page %@ of %@.", iString, numberOfPagesString];
                [activityView.status performSelectorOnMainThread:@selector(setText:) withObject:text waitUntilDone:NO];
            }
        }
        UIGraphicsEndPDFContext();
        
        dispatch_semaphore_signal(s1);
        
    });
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);
    [activityView removeFromSuperview];
    
}

- (void)disableUserInteraction:(UIView *)view {
    for (UIView *subview in [view subviews]) {
        if ([subview isKindOfClass:[UILabel class]]) {
            [(UILabel *)subview performSelectorOnMainThread:@selector(setTextColor:) withObject:[UIColor lightGrayColor] waitUntilDone:NO];
        } else if ([subview isKindOfClass:[UIImageView class]]) {
            dispatch_queue_t dipatchQueueMain = dispatch_get_main_queue();
            dispatch_sync(dipatchQueueMain, ^{
                subview.alpha = 0.3333f;
            });
        }
        [self disableUserInteraction:subview];
    }
}

@end
