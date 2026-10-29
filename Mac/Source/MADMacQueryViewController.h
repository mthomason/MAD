//
//  MADMacQueryViewController.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacQueryViewController_h
#define MADMacQueryViewController_h

#import <Cocoa/Cocoa.h>

@class MADMacDocument;

NS_ASSUME_NONNULL_BEGIN

@interface MADMacQueryViewController : NSViewController

@property (nonatomic, weak, nullable) MADMacDocument *document;

- (instancetype)initWithDocument:(MADMacDocument *)document;
- (void)reloadFromDocument;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacQueryViewController_h */
