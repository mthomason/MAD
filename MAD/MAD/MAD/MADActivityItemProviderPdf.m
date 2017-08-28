//
//  MTActivityItemProviderPdf.m
//  MAD
//
//  Created by Michael Thomason on 2/21/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADActivityItemProviderPdf.h"
#import "MADActivityItemProviderDelegate.h"

#import <UIKit/UIGraphics.h>
#import <UIKit/UIActivity.h>
#import <UIKit/UIActivityViewController.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIImageView.h>

#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import "MADocument.h"
#import "MADReportFormatter.h"
#import "MADPrintPageRenderer.h"

#import "MADActivityIndicator.h"
#import "MTPaper.h"
#import "MADDataTableFast.h"
#import "MADNotificationDidFormatPage.h"

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

@interface  MADActivityItemProviderPdf ()
    <MADDocumentStatusProtocol>
    @property (nonatomic, weak, readwrite) UIActivityViewController *activityViewController;
    @property (nonatomic, weak, readwrite) MADActivityIndicator *activityIndicatorController;
@end

@implementation MADActivityItemProviderPdf

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
    UIActivityViewController *activityViewController = _activityViewController;
    if ([self.activityType caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {    //Printer
        if (activityViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self.delegate showPrintDialog]; //Need some help getting out of this popover!!!
        }
        item = self.placeholderItem;
    } else {                                                                                    //Return URL to PDF printout.
        NSString *temporaryDirectoryPath = NSTemporaryDirectory();
        NSURL *temporaryDirectory = [NSURL fileURLWithPath: temporaryDirectoryPath];
        item = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
        
        [self writeToPdf:item withViewController:activityViewController];
    }
    return item;
}

- (void)setStatusText:(NSString *)text {
    NSString *statusText = text.copy;
    [self.activityIndicatorController.status setText:statusText];
}

- (void)writeToPdf:(NSURL *)fileURL withViewController:(UIViewController *)window {

    [self disableUserInteraction:window.view];

    UIView *mainWindow = [UIApplication sharedApplication].keyWindow.viewForLastBaselineLayout;

    MADActivityIndicator *activityView;
    activityView = [[MADActivityIndicator alloc] initWithFrame:CellDefaultBounds()];
    activityView.center = mainWindow.center;
    
    [mainWindow performSelectorOnMainThread: @selector(addSubview:)
                                 withObject: activityView
                              waitUntilDone: YES];
    
    MADocument *document = _document;
    self.activityIndicatorController = activityView;
    //document.statusLabel = activityView;
    document.documentStatusProtocol = self;
    
    typeof(document) __weak weakdoc = document;
    
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(dipatchQueue, ^{
        
        MADocument *sdocument = weakdoc;
        NSDictionary <NSString *, NSString *> *options;
        options = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    @"MAD® Designer", (NSString *)kCGPDFContextCreator, nil];
        CGRect letterRect = [MTPaper rectLetter];
        NSArray *sortDescriptors = sdocument.sortDescriptors;
        
        [sdocument.dataTable sortUsingDescriptors:sortDescriptors];
        MADReportFormatter *reportFormatter;
        reportFormatter = [[MADReportFormatter alloc] initWithDocument: sdocument
                                                               options: MADReportFormatterOptionsMargin];
        reportFormatter.overrideIdentifier = @"madpreview";
        reportFormatter.didRefresh = YES;
        reportFormatter.layoutSize = letterRect.size;
        
        [[NSNotificationCenter defaultCenter] addObserver: sdocument
                                                 selector: @selector(reportFormatterDidFormatPage:)
                                                     name: MADNotificationDidFormatPagesName
                                                   object: reportFormatter];
        
        
        [reportFormatter setMarginUsingPrintableRect:PdfTrimBox(letterRect)];
        [reportFormatter format:letterRect.size contentChanged:NO];
        
        
        [[NSNotificationCenter defaultCenter] removeObserver: sdocument
                                                        name: MADNotificationDidFormatPagesName
                                                      object: reportFormatter];
        
        MADPrintPageRenderer *printPageRenderer;
        printPageRenderer = [[MADPrintPageRenderer alloc] initWithDataSource:document];
        
        NSString *filePath = fileURL.path.copy;
        UIGraphicsBeginPDFContextToFile(filePath, letterRect, options);
        
        NSValue *trimBox = [NSValue valueWithCGRect:PdfTrimBox(letterRect)];
        NSDictionary <NSString *, NSValue *> *boxInfo;
        boxInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                    trimBox, (__bridge NSString *)kCGPDFContextTrimBox, nil];
        
        id pagesWrapper = [[NSNumber alloc] initWithUnsignedInteger: reportFormatter.numberOfPages];
        
        id totalPages = [NSNumberFormatter localizedStringFromNumber: pagesWrapper
                                                         numberStyle: NSNumberFormatterDecimalStyle];
        
        for (NSUInteger i=0; i<reportFormatter.numberOfPages; i++) {

            NSNumber *pageNumber;
            NSString *page, *text;

            UIGraphicsBeginPDFPageWithInfo(letterRect, boxInfo);
            [printPageRenderer drawPageAtIndex:(NSInteger)i inRect:PdfTrimBox(letterRect)];
            
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
    for (UIView *subview in view.subviews) {
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
