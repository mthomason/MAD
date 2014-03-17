//
//  MTActivityReportPrintPreview.h
//  MAD
//
//  Created by Michael Thomason on 2/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTActivityReportPrintPreview_h
#define Reports_MTActivityReportPrintPreview_h

#import <UIKit/UIKit.h>

@protocol MTActivityReportPrintPreviewDelegate <NSObject>
@required
- (void)prepareForInteractionController:(UIDocumentInteractionController *)controller withCompletionHandler:(void (^)(BOOL))completionHandler;

- (UIViewController *)previewViewControllerForInteractionController:(UIDocumentInteractionController *)controller;
@end

@interface MTActivityReportPrintPreview : UIActivity

@property (nonatomic, assign) id <MTActivityReportPrintPreviewDelegate> delegate;

@end

#endif
