//
//  MADMacConnectionWindowController.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacConnectionWindowController_h
#define MADMacConnectionWindowController_h

#import <Cocoa/Cocoa.h>

@class MADCredential, MADDatabaseConnection, MADHeadlessDocument, MADMacDocument;

NS_ASSUME_NONNULL_BEGIN

@interface MADMacConnectionWindowController : NSWindowController

@property (nonatomic, weak, readonly, nullable) MADMacDocument *editingDocument;
@property (nonatomic, strong, readonly, nullable) MADCredential *lastCredentials;
@property (nonatomic, assign, readonly) BOOL savePasswordInKeychain;

@property (nonatomic, copy, nullable) void (^onDocumentCreated)(MADHeadlessDocument *document, NSURL *savedURL);
@property (nonatomic, copy, nullable) void (^onConnectionUpdated)(MADDatabaseConnection *connection, MADCredential * _Nullable credentials);

/// Initializes the controller in "New Report from Database Connection" mode.
- (instancetype)init;

/// Initializes the controller in "Edit / Reconnect Database Connection" mode for an existing document.
- (instancetype)initWithDocument:(nullable MADMacDocument *)document
					statusPrompt:(nullable NSString *)statusPrompt;

- (void)driverPopupChanged:(nullable id)sender;

- (nullable MADDatabaseConnection *)buildConnectionWithCredentials:(MADCredential * _Nullable __autoreleasing * _Nullable)outCredentials
															 error:(NSError * _Nullable __autoreleasing * _Nullable)outError;

- (BOOL)applyToEditingDocumentAndError:(NSError * _Nullable __autoreleasing * _Nullable)outError;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacConnectionWindowController_h */
