//
//  MADMacConnectionWindowController.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacConnectionWindowController_h
#define MADMacConnectionWindowController_h

#import <Cocoa/Cocoa.h>

@class MADHeadlessDocument;

NS_ASSUME_NONNULL_BEGIN

@interface MADMacConnectionWindowController : NSWindowController

@property (nonatomic, copy, nullable) void (^onDocumentCreated)(MADHeadlessDocument *document, NSURL *savedURL);

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacConnectionWindowController_h */
