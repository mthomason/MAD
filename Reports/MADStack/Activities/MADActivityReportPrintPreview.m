//
//  MADActivityReportPrintPreview.m
//  MAD
//
//  Created by Michael Thomason on 2/21/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADActivityReportPrintPreview.h"
#import <UIKit/UIDocumentInteractionController.h>
#import <UIKit/UIScreen.h>
#import <UIKit/UIImage.h>

typedef UIDocumentInteractionController MADocumentActivityController;

@interface MADActivityReportPrintPreview()
    <UIDocumentInteractionControllerDelegate>

    @property (nonatomic, strong) MADocumentActivityController *activityController;
    @property (nonatomic, copy) NSURL *pdfurl;

@end

@implementation MADActivityReportPrintPreview

- (NSString *)activityType {
    return @"MADActivityReportPrintPreview";
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Print Preview", @"Print Preview");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"MADActivityProvidence"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]]) {
            _pdfurl = [((id <NSCopying>)activityItem) copyWithZone:nil];
        }
    }
}

- (UIViewController *)activityViewController {
    return nil;
}

- (void)performActivity {
    NSURL *pdfurl = self.pdfurl;
    MADocumentActivityController *controller = [MADocumentActivityController  interactionControllerWithURL:pdfurl];
    controller.delegate = self;
    self.activityController = controller;
    
    UIDocumentInteractionController * __weak weakController = self.activityController;
    [self.delegate prepareForInteractionController: weakController
                                        completion: ^(BOOL success) {
        if (success) {
            [weakController presentPreviewAnimated:YES];
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
