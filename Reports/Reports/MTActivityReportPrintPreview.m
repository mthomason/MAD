//
//  MTActivityReportPrintPreview.m
//  MAD
//
//  Created by Michael Thomason on 2/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTActivityReportPrintPreview.h"
#import "AppDelegate.h"
#import "UIDevice+Hack.h"

@interface MTActivityReportPrintPreview()
    <UIDocumentInteractionControllerDelegate>

@property (nonatomic, retain) UIDocumentInteractionController *interactionController;
@property (nonatomic, retain) NSURL *pdfurl;

@end

@implementation MTActivityReportPrintPreview

- (void)dealloc {
    [_interactionController release];
    [_pdfurl release];
    [super dealloc];
}

- (NSString *)activityType {
    return @"MTActivityReportPrintPreview";
}

- (NSString *)activityTitle {
    return @"Print Preview";
}

- (UIImage *)activityImage {
    NSString *imageName = [UIDevice isPad] ? @"MTActivityPreview-76" : @"MTActivityPreview";
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
    UIDocumentInteractionController *c = [[UIDocumentInteractionController  interactionControllerWithURL:[self pdfurl]] retain];
    [c setDelegate:self];
    [self setInteractionController:c];
    [[self delegate] prepareForInteractionController:c withCompletionHandler:^(BOOL success) {
        if (success) {
            [c presentPreviewAnimated:YES];
        }
    }];
    [c release];
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    [self activityDidFinish:YES];
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *) controller {
    UIViewController *result = [[[self delegate] previewViewControllerForInteractionController:controller] retain];
    return [result autorelease];
}

@end
