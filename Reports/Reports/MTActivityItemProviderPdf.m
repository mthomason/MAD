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
        
        [self.document writeToPdf:item withViewController:self.activityViewController];
    }
    return item;
}

@end
