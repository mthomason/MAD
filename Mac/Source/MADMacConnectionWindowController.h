//
//  MADMacConnectionWindowController.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacConnectionWindowController_h
#define MADMacConnectionWindowController_h

#import <Cocoa/Cocoa.h>

@class MADCredential, MADDatabaseConnection, MADHeadlessDocument, MADMacDocument, RptqQuery;

NS_ASSUME_NONNULL_BEGIN

@interface MADMacConnectionWindowController : NSWindowController

@property (nonatomic, weak, readonly, nullable) MADMacDocument *editingDocument;
@property (nonatomic, strong, readonly, nullable) MADCredential *lastCredentials;
@property (nonatomic, assign, readonly) BOOL savePasswordInKeychain;

@property (nonatomic, copy, nullable) void (^onDocumentCreated)(MADHeadlessDocument *document, NSURL *savedURL);
@property (nonatomic, copy, nullable) void (^onConnectionUpdated)(MADDatabaseConnection *connection, MADCredential * _Nullable credentials);

/// When YES, the primary button builds, tests, and hands back the connection instead
/// of creating a document or applying it to an editing document (used to add a
/// composed source query).
@property (nonatomic, assign) BOOL sourcePickerMode;
@property (nonatomic, copy, nullable) void (^onSourceConnectionBuilt)(MADDatabaseConnection * _Nullable connection, MADCredential * _Nullable credentials, NSError * _Nullable error);

/// When set (edit mode), the sheet edits this query's own connection instead of the
/// document's default database.  Used to reconnect a composed source query.
@property (nonatomic, weak, nullable) RptqQuery *targetQuery;

/// Repoints an already-built edit sheet at one composition source and prefills it
/// from that source's connection, credential hint, and Keychain entry.  `prompt`
/// replaces the status line (it usually names the source being asked about).
- (void)prepareForTargetQuery:(RptqQuery *)query prompt:(nullable NSString *)prompt;

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
