//
//  MADDocumentCreationManager.m
//  MAD Designer
//
//  Created by Michael on 9/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDocumentCreationManager.h"
#import "MADOperationCreateDocument.h"
#import "MADDocumentCreationManagerProtocol.h"
#import <MADFoundation/madlog.h>

#import <MADFoundation/MADOperationObserver.h>
#import <MADFoundation/MADOperationQueue.h>

#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>

@interface MADDocumentCreationManager () <MADOperationObserver>

- (instancetype)initWithFilename: (NSString *)filename
						delegate: (NSObject <MADDocumentCreationManagerProtocol> *)delegate
			  documentsDirectory: (NSURL *)documentsDirectory
			  databaseConnection: (MADDatabaseConnection *)databaseConnection
				  viewController: (UIViewController *)viewController;

@property (nonatomic, strong) MADOperationQueue *credentialQueue;
@property (nonatomic, weak) NSObject <MADDocumentCreationManagerProtocol> *delegate;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSURL *directory;
@property (nonatomic, strong) MADDatabaseConnection *connection;

@end

@implementation MADDocumentCreationManager

- (instancetype)initWithFilename: (NSString *)filename
						delegate: (NSObject <MADDocumentCreationManagerProtocol> *)delegate
			  documentsDirectory: (NSURL *)documentsDirectory
			  databaseConnection: (MADDatabaseConnection *)databaseConnection
				  viewController: (UIViewController *)viewController {
	if (self = [super init]) {
		MADOperationQueue *credentialQueue = [[MADOperationQueue alloc] init];
		self.credentialQueue = credentialQueue;
		self.delegate = delegate;
		self.filename = [filename copy];
		self.directory = [documentsDirectory copy];
		self.connection = databaseConnection;
		self.viewController = viewController;
		MADLogDebug("MADDocumentCreationManager <%p> initialized.", self);
	}
	return self;
}

- (void)start {
	MADLogDebug("MADDocumentCreationManager <%p> start called. Filename: \"%@\"", self, self.filename);
	[self.credentialQueue cancelAllOperations];
	MADLogDebug("MADDocumentCreationManager <%p> cancelled any existing operations on queue: %@",
				self, self.credentialQueue.name);
	MADOperationCreateDocument *createDocument = [[MADOperationCreateDocument alloc] initWithFilename: self.filename
																				   documentsDirectory: self.directory
																				   databaseConnection: self.connection
																					   viewController: self.viewController];
	MADLogDebug("MADDocumentCreationManager <%p> created MADOperationCreateDocument <%p> for filename: \"%@\"",
				self, createDocument, self.filename);
	[createDocument addObserver:self];
	MADLogDebug("MADDocumentCreationManager <%p> added self as observer to MADOperationCreateDocument <%p>",
				self, createDocument);
	[self.credentialQueue addOperation:createDocument];
	MADLogDebug("MADDocumentCreationManager <%p> added MADOperationCreateDocument <%p> to queue: %@",
				self, createDocument, self.credentialQueue.name);
}

#pragma mark -
#pragma mark MADOperationObserver

- (void)operationDidStart:(MADOperation *)operation { }

- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation { }

- (void)operationDidFinish:(nonnull MADOperation *)operation errors:(nullable NSArray<NSError *> *)errors {
	MADLogDebug("MADDocumentCreationManager <%p> observed operationDidFinish: <%p:%@>. Error count: %lu",
				self, operation, operation.name, (unsigned long)errors.count);
	
	if (errors && errors.count > 0) {
		MADLogError("MADDocumentCreationManager <%p> observed operation <%p:%@> finished with %lu error(s):",
					self, operation, operation.name, (unsigned long)errors.count);
		for (NSError *error in errors) {
			MADLogError("  Error for op <%p:%@>: %@ %@", self, operation, operation.name, error);
		}
	}
	
	BOOL success = NO;
	if ([operation isKindOfClass:[MADOperationCreateDocument class]]) {
		MADOperationCreateDocument *createDocOp = (MADOperationCreateDocument *)operation;
		// Assuming MADOperationCreateDocument has these properties.
		// These properties need to be defined in MADOperationCreateDocument.h for this to compile.
		if (createDocOp.isSuccessConnection && createDocOp.isSuccessCreate) {
			success = YES;
		}
		MADLogDebug("MADDocumentCreationManager <%p> MADOperationCreateDocument finished. Connection success: %s, Create success: %s. Overall success for delegate: %s",
					self,
					createDocOp.isSuccessConnection ? "YES" : "NO",
					createDocOp.isSuccessCreate ? "YES" : "NO",
					success ? "YES" : "NO");
	} else {
		MADLogDebug("MADDocumentCreationManager <%p> observed finished operation was not MADOperationCreateDocument. Type: %@. Assuming failure for delegate callback related to document creation.",
					self, NSStringFromClass([operation class]));
		// If other operations could run on this queue and be observed, `success` should only be determined
		// for MADOperationCreateDocument.
	}
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		MADLogDebug("MADDocumentCreationManager <%p> dispatching to delegate documentCreationManager:didFinish: %s",
					self, success ? "YES" : "NO");
		NSObject <MADDocumentCreationManagerProtocol> *delegate = self.delegate;
		if (delegate && [delegate respondsToSelector:@selector(documentCreationManager:didFinish:)]) {
			[delegate documentCreationManager:self didFinish:success];
		} else {
			MADLogError("MADDocumentCreationManager <%p> delegate not set or does not respond to documentCreationManager:didFinish:", self);
		}
	}];
}

@end
