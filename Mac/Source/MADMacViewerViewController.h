//
//  MADMacViewerViewController.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacViewerViewController_h
#define MADMacViewerViewController_h

#import <Cocoa/Cocoa.h>

@class MADMacDocument;

NS_ASSUME_NONNULL_BEGIN

@interface MADMacViewerViewController : NSViewController

@property (nonatomic, weak, nullable) MADMacDocument *document;

- (instancetype)initWithDocument:(MADMacDocument *)document;
- (void)reloadPreview;
- (void)refreshReportAction:(nullable id)sender;
- (void)exportReportAction:(nullable id)sender;
- (void)printReportAction:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacViewerViewController_h */
