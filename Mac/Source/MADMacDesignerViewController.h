//
//  MADMacDesignerViewController.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacDesignerViewController_h
#define MADMacDesignerViewController_h

#import <Cocoa/Cocoa.h>

@class MADMacDocument;

NS_ASSUME_NONNULL_BEGIN

@interface MADMacDesignerViewController : NSViewController

@property (nonatomic, weak, nullable) MADMacDocument *document;

- (instancetype)initWithDocument:(MADMacDocument *)document;
- (void)reloadFromDocument;

- (void)addStaticLabelElement:(nullable id)sender;
- (void)addDataFieldElement:(nullable id)sender;
- (void)addAggregateElement:(nullable id)sender;
- (void)addBarcodeElement:(nullable id)sender;
- (void)addImageElement:(nullable id)sender;
- (void)deleteSelectedElements:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacDesignerViewController_h */
