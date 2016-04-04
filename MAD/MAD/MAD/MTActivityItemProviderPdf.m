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
#import "MADActivityIndicator.h"
#import "MTPaper.h"
#import "MTDataTableFast.h"
#import "MADNotificationDidFormatPage.h"

@interface  MTActivityItemProviderPdf ()

@property (nonatomic, weak, readwrite) UIActivityViewController *activityViewController;

@end

@implementation MTActivityItemProviderPdf

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
    id result = [super activityViewController:activityViewController itemForActivityType:activityType];
    self.activityViewController = activityViewController;
    return result;
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController dataTypeIdentifierForActivityType:(NSString *)activityType {
    self.activityViewController = activityViewController;
    return activityType == nil ? @"" : [super activityViewController:activityViewController dataTypeIdentifierForActivityType:activityType];
}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(NSString *)activityType suggestedSize:(CGSize)size {
    self.activityViewController = activityViewController;
    return [super activityViewController:activityViewController thumbnailImageForActivityType:activityType suggestedSize:size];
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    self.activityViewController = activityViewController;
    return [super activityViewControllerPlaceholderItem:activityViewController];
}

- (id)item {
    id item = nil;
    if ([[self activityType] caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {    //Printer
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
    MADActivityIndicator *activityView = [[MADActivityIndicator alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 200.0000f)];
    activityView.center = mainWindow.center;
    
    [mainWindow performSelectorOnMainThread: @selector(addSubview:)
                                 withObject: activityView
                              waitUntilDone: YES];
    [self.document setStatusLabel:activityView];
    
    MADocument * __weak weakdoc = self.document;
    
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(dipatchQueue, ^{
        
        
        NSDictionary *options = @{(NSString *)kCGPDFContextCreator :  @"MAD® Designer"};
        CGRect letterRect = [MTPaper rectLetter];
        NSArray *sortDescriptors = weakdoc.sortDescriptors;
        
        [weakdoc.mainDataTable sortUsingDescriptors:sortDescriptors];
        MTReportFormatter *rf = [MTReportFormatter reportFormatterWithQuery: weakdoc.mainQuery layout: weakdoc
                                                                    options: MTReportFormatterOptionsMargin];
        rf.cachedDelegate = weakdoc;
        rf.dataDelegate = weakdoc;
        rf.overrideIdentifier = @"madpreview";
        rf.didRefresh = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver: weakdoc selector: @selector(reportFormatterDidFormatPage:)
                                                     name: MADNotificationDidFormatPagesName object: rf];
        
        
        rf.layoutSize = letterRect.size;
        UIEdgeInsets border = UIEdgeInsetsMake(halfinch(), halfinch(), halfinch(), halfinch());
        CGRect trimBoxRect = UIEdgeInsetsInsetRect(letterRect, border);
        [rf setMarginUsingPrintableRect:trimBoxRect];
        rf.datasource = weakdoc;
        [rf formatForSize:letterRect.size contentChanged:NO];
        
        
        [[NSNotificationCenter defaultCenter] removeObserver: weakdoc
                                                        name: MADNotificationDidFormatPagesName
                                                      object: rf];
        
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: rf
                                                                                                                  dataTable: weakdoc.mainDataTable];
        NSUInteger numberOfPages = rf.numberOfPages;
        UIGraphicsBeginPDFContextToFile(filepath.path, letterRect, options);
        
        NSValue *trimBox = [NSValue valueWithCGRect:trimBoxRect];
        NSDictionary *boxInfo = @{(__bridge NSString *)kCGPDFContextTrimBox: trimBox};
        NSString *numberOfPagesString = [NSNumberFormatter localizedStringFromNumber:@(numberOfPages)
                                                                         numberStyle:NSNumberFormatterDecimalStyle];
        for (NSUInteger i=0; i<numberOfPages; i++) {
            @autoreleasepool {
                UIGraphicsBeginPDFPageWithInfo(letterRect, boxInfo);
                [printPageRender drawPageAtIndex:(NSInteger)i inRect:trimBoxRect];
                NSString *iString = [NSNumberFormatter localizedStringFromNumber:@(i) numberStyle:NSNumberFormatterDecimalStyle];
                NSString *text = [[NSString alloc] initWithFormat:@"Drawing page %@ of %@.", iString, numberOfPagesString];
                [activityView.status performSelectorOnMainThread:@selector(setText:) withObject:text waitUntilDone:NO];
            }
        }
        UIGraphicsEndPDFContext();
        
        dispatch_semaphore_signal(s1);
        
    });
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);
    [activityView removeFromSuperview];
    window.view.userInteractionEnabled = YES;
    
}

static inline CGFloat halfinch() {
    return 72.0000 / 72.0000;
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
