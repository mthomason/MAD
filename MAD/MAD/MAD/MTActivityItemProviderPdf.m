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
#import "MADActivityItemProviderPdfDelegate.h"
#import "MADocument.h"
#import "MTReportFormatter.h"
#import "MTReportViewerPrintPageRenderer.h"
#import "MADActivityIndicator.h"
#import "MTPaper.h"
#import "MTDataTableFast.h"
#import "MADNotificationDidFormatPage.h"

#import <UIKit/UIGraphics.h>
#import <UIKit/UIActivity.h>
#import <UIKit/UIActivityViewController.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIImageView.h>

#import <MADCocoaExtensions/CGGeometry+Extras.h>

static inline CGFloat halfinch();
static inline CGFloat halfinch() {
    return 72.0000 / 72.0000;
}

static inline CGRect CellDefaultBounds();
static inline CGRect CellDefaultBounds() {
    return MADRectOfSize(CGSizeMake(230.0000f, 200.0000f));
}

static inline UIEdgeInsets PdfBorder();
static inline UIEdgeInsets PdfBorder() {
    return UIEdgeInsetsMake(halfinch(), halfinch(), halfinch(), halfinch());
}

static inline CGRect PdfTrimBox(CGRect rect);
static inline CGRect PdfTrimBox(CGRect rect) {
    return UIEdgeInsetsInsetRect(rect, PdfBorder());
}

@interface  MTActivityItemProviderPdf ()
    @property (nonatomic, weak, readwrite) UIActivityViewController *activityViewController;
@end

@implementation MTActivityItemProviderPdf

- (id)activityViewController:(UIActivityViewController *)activityViewController
         itemForActivityType:(NSString *)activityType {
    
    id result = [super activityViewController: activityViewController
                          itemForActivityType: activityType];
    
    self.activityViewController = activityViewController;
    
    return result;
    
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController
   dataTypeIdentifierForActivityType:(NSString *)activityType {
   
    self.activityViewController = activityViewController;
    return activityType == nil ? @"" : [super activityViewController: activityViewController
                                   dataTypeIdentifierForActivityType: activityType];
}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController
      thumbnailImageForActivityType:(NSString *)activityType suggestedSize:(CGSize)size {
    self.activityViewController = activityViewController;
    return [super activityViewController: activityViewController
           thumbnailImageForActivityType: activityType suggestedSize: size];
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    self.activityViewController = activityViewController;
    return [super activityViewControllerPlaceholderItem:activityViewController];
}

- (id)item {
    id item = nil;
    if ([self.activityType caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {    //Printer
        if (self.activityViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
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

    UIView *mainWindow = [UIApplication sharedApplication].keyWindow.viewForBaselineLayout;

    MADActivityIndicator *activityView;
    activityView = [[MADActivityIndicator alloc] initWithFrame:CellDefaultBounds()];
    activityView.center = mainWindow.center;
    
    [mainWindow performSelectorOnMainThread: @selector(addSubview:)
                                 withObject: activityView
                              waitUntilDone: YES];
    
    self.document.statusLabel = activityView;
    
    MADocument * __weak weakdoc = self.document;
    
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(dipatchQueue, ^{
        
        NSDictionary *options;
        options = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    @"MAD® Designer", (NSString *)kCGPDFContextCreator, nil];
        CGRect letterRect = [MTPaper rectLetter];
        NSArray *sortDescriptors = weakdoc.sortDescriptors;
        
        [weakdoc.mainDataTable sortUsingDescriptors:sortDescriptors];
        MTReportFormatter *reportFormatter;
        reportFormatter = [[MTReportFormatter alloc] initWithDocument: weakdoc
                                                              options: MTReportFormatterOptionsMargin];
        reportFormatter.cachedDelegate = weakdoc;
        reportFormatter.dataDelegate = weakdoc;
        reportFormatter.datasource = weakdoc;
        reportFormatter.overrideIdentifier = @"madpreview";
        [reportFormatter initialize];
        reportFormatter.didRefresh = true;
        reportFormatter.layoutSize = letterRect.size;
        
        [[NSNotificationCenter defaultCenter] addObserver: weakdoc
                                                 selector: @selector(reportFormatterDidFormatPage:)
                                                     name: MADNotificationDidFormatPagesName
                                                   object: reportFormatter];
        
        
        [reportFormatter setMarginUsingPrintableRect:PdfTrimBox(letterRect)];
        [reportFormatter formatForSize:letterRect.size contentChanged:NO];
        
        
        [[NSNotificationCenter defaultCenter] removeObserver: weakdoc
                                                        name: MADNotificationDidFormatPagesName
                                                      object: reportFormatter];
        
        MTReportViewerPrintPageRenderer *printPageRender;
        printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: reportFormatter
                                                                                 dataTable: weakdoc.mainDataTable];

        UIGraphicsBeginPDFContextToFile(filepath.path, letterRect, options);
        
        NSValue *trimBox = [NSValue valueWithCGRect:PdfTrimBox(letterRect)];
        NSDictionary *boxInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        trimBox, (__bridge NSString *)kCGPDFContextTrimBox, nil];
        
        id pagesWrapper = [[NSNumber alloc] initWithUnsignedInteger: reportFormatter.numberOfPages];
        
        id totalPages = [NSNumberFormatter localizedStringFromNumber: pagesWrapper
                                                         numberStyle: NSNumberFormatterDecimalStyle];
        
        for (NSUInteger i=0; i<reportFormatter.numberOfPages; i++) {

            NSNumber *pageNumber;
            NSString *page, *text;

            UIGraphicsBeginPDFPageWithInfo(letterRect, boxInfo);
            [printPageRender drawPageAtIndex:(NSInteger)i inRect:PdfTrimBox(letterRect)];
            
            pageNumber = [[NSNumber alloc] initWithUnsignedInteger: i];
            
            page  = [NSNumberFormatter localizedStringFromNumber: pageNumber
                                                     numberStyle: NSNumberFormatterDecimalStyle];
            
            text = [[NSString alloc] initWithFormat:@"Drawing page %@ of %@.", page, totalPages];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                activityView.status.text = text.copy;
            }];
            
        }
        UIGraphicsEndPDFContext();
        
        dispatch_semaphore_signal(s1);
        
    });
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [activityView removeFromSuperview];
        window.view.userInteractionEnabled = YES;
    }];
    
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
