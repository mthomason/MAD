//
//  MADMacWindowController.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacWindowController_h
#define MADMacWindowController_h

#import <Cocoa/Cocoa.h>

@class MADMacDocument, MADMacQueryViewController, MADMacDesignerViewController, MADMacViewerViewController;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MADMacWorkspaceTab) {
	MADMacWorkspaceTabQuery = 0,
	MADMacWorkspaceTabDesigner = 1,
	MADMacWorkspaceTabViewer = 2,
};

@interface MADMacWindowController : NSWindowController <NSToolbarDelegate>

@property (nonatomic, weak, readonly, nullable) MADMacDocument *madDocument;
@property (nonatomic, strong, readonly) MADMacQueryViewController *queryViewController;
@property (nonatomic, strong, readonly) MADMacDesignerViewController *designerViewController;
@property (nonatomic, strong, readonly) MADMacViewerViewController *viewerViewController;

- (instancetype)initWithDocument:(MADMacDocument *)document;
- (void)switchToWorkspaceTab:(MADMacWorkspaceTab)tab;
- (void)refreshReportAction:(nullable id)sender;
- (void)exportReportAction:(nullable id)sender;
- (void)printReportAction:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacWindowController_h */
