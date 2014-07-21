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
#import "MTReportViewerPrintPageRenderer.h"
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "MAReportDocument.h"
#import "MTQuery.h"
#import "MTReportFormatter.h"
#import "MTReportViewerPrintPageRenderer.h"

@interface  MTActivityItemProviderPdf ()

@property (nonatomic, weak, readwrite) UIActivityViewController *activityViewController;

@end

@implementation MTActivityItemProviderPdf

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
    [self setActivityViewController:activityViewController];
    return [super activityViewController:activityViewController itemForActivityType:activityType];
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController dataTypeIdentifierForActivityType:(NSString *)activityType {
    [self setActivityViewController:activityViewController];
    return [super activityViewController:activityViewController dataTypeIdentifierForActivityType:activityType];
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
    NSLog(@"Activity type: %@", [self activityType]);
    id item = nil;
    if ([[self activityType] caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {
        item = [super item];
    } else {
        
        NSString *temporaryDirectoryPath = NSTemporaryDirectory();
        NSURL *temporaryDirectory = [NSURL fileURLWithPath: temporaryDirectoryPath];
        item = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
        
        MAReportDocument *reportDocument = [[AppDelegate app] activeDocument];
        [reportDocument writeToPdf:item withViewController:[self activityViewController]];
    }
    
    
    return item;
}

@end
