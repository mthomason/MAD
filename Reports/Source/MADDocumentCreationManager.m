//
//  MADDocumentCreationManager.m
//  MAD Designer
//
//  Created by Michael on 9/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDocumentCreationManager.h"
#import "MADOperationCreateDocument.h"
#import "MADDocumentCreationManagerProtocol.h"
#import "madlog.h"

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
		self.filename = filename.copy;
		self.directory = documentsDirectory.copy;
		self.connection = databaseConnection;
		self.viewController = viewController;
	}
	return self;
}

- (void)start {
	[self.credentialQueue cancelAllOperations];
	
	
	MADOperationCreateDocument *createDocument;
	createDocument = [[MADOperationCreateDocument alloc] initWithFilename: self.filename
													   documentsDirectory: self.directory
													   databaseConnection: self.connection
														   viewController: self.viewController];
	[createDocument addObserver:self];
	[self.credentialQueue addOperation:createDocument];
}

#pragma mark -
#pragma mark MADOperationObserver

- (void)operationDidStart:(MADOperation *)operation { }

- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation { }

- (void)operationDidFinish:(nonnull MADOperation *)operation errors:(nullable NSArray<NSError *> *)errors {
	os_log_info(GetDesignerLog(), "%s\t%s", __PRETTY_FUNCTION__, operation.description.UTF8String);
	
	BOOL success = NO;
	if ([operation isKindOfClass:[MADOperationCreateDocument class]]) {
		if (((MADOperationCreateDocument *)operation).isSuccessConnection &&
			((MADOperationCreateDocument *)operation).isSuccessCreate) {
			success = YES;
		}
	}
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		[self.delegate documentCreationManager:self didFinish:success];
	}];
}

@end
