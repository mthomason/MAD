//
//  MTActivityReportPrintPreview.m
//  MAD
//
//  Created by Michael Thomason on 2/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTActivityReportPrintPreview.h"
#import "UIDevice+Hack.h"

@interface MTActivityReportPrintPreview()
    <UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) UIDocumentInteractionController *interactionController;
@property (nonatomic, strong) NSURL *pdfurl;

@end

@implementation MTActivityReportPrintPreview

- (NSString *)activityType {
    return @"MTActivityReportPrintPreview";
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Print Preview", @"Print Preview");
}

- (UIImage *)activityImage {
    NSString *imageName = [UIDevice isPad] ? @"MTActivityProvidence~iPad" : @"MTActivityProvidence";
    return [UIImage imageNamed:imageName];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]]) {
            [self setPdfurl:activityItem];
        }
    }
}

- (UIViewController *)activityViewController {
    return nil;
}

- (void)performActivity {
    UIDocumentInteractionController *c = [UIDocumentInteractionController  interactionControllerWithURL:[self pdfurl]];
    [c setDelegate:self];
    [self setInteractionController:c];
    [self.delegate prepareForInteractionController:c withCompletionHandler:^(BOOL success) {
        if (success) {
            [c presentPreviewAnimated:YES];
        }
    }];
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    [self activityDidFinish:YES];
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *) controller {
    UIViewController *result = [self.delegate previewViewControllerForInteractionController:controller];
    return result;
}

@end
