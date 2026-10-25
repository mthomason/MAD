//
//  MADActivityReportPrintPreview.h
//  MAD
//
//  Created by Michael Thomason on 2/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADActivityReportPrintPreview_h
#define Reports_MADActivityReportPrintPreview_h

#import <UIKit/UIActivity.h>

@class UIDocumentInteractionController;

@protocol MADActivityReportPrintPreviewDelegate <NSObject>
@required
- (void)prepareForInteractionController:(UIDocumentInteractionController *)controller
							 completion:(void (^)(BOOL))completion;

- (UIViewController *)previewViewControllerForInteractionController:(UIDocumentInteractionController *)controller;
@end

@interface MADActivityReportPrintPreview : UIActivity

@property (nonatomic, weak) id <MADActivityReportPrintPreviewDelegate> delegate;

@end

#endif
