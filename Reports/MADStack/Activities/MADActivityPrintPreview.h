//
//  MADActivityPrintPreview.h
//  MAD
//
//  Created by Michael Thomason on 2/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADActivityPrintPreview_h
#define Reports_MADActivityPrintPreview_h

#import <UIKit/UIActivity.h>

@class UIDocumentInteractionController;

@protocol MADActivityPrintPreviewDelegate <NSObject>
 @required
    - (void)prepareForInteractionController:(UIDocumentInteractionController *)controller completion:(void (^)(BOOL))completion;

    - (UIViewController *)previewViewControllerForInteractionController:(UIDocumentInteractionController *)controller;
@end

@interface MADActivityPrintPreview : UIActivity

    @property (nonatomic, weak) id <MADActivityPrintPreviewDelegate> delegate;

@end

#endif
