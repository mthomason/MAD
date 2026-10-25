//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADCLIDocument.m
//  MAD Designer
//

#import "MADCLIDocument.h"
#import "MADCLI.h"

// The refresh chain.  It lives in the MAD framework (it used to be compiled in from
// the application target), so the CLI and the application run the same code by
// linking it rather than by copying it.  docs/project/MAD_CLI.md section 4.1, docs/project/ROADMAP.md §3.4.
#import <MAD/MADOperationRefresh.h>
#import <MAD/MADOperationRefreshInitialize.h>
#import <MAD/MADOperationRefreshInitalizeMainDataTable.h>

#import <MAD/MADConstants.h>
#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADCredential.h>

#if __APPLE__
// The app's document class.  MADocument is a UIDocument, so a process with no run
// loop gets a MADHeadlessDocument instead -- the same data half and the same render
// half, on the protocols the refresh chain and the exporters take.
#import <MAD/MADocument.h>
#else
#import <MAD/MADHeadlessDocument.h>
#endif

#if __APPLE__
static NSError *MADCLIDocumentError(NSString *message) {
	return [NSError errorWithDomain: @"MADCLI" code: MADCLIExitBadDocument
						   userInfo: @{ NSLocalizedDescriptionKey: message }];
}
#endif

/// Stands in for MADOperationGetCredentials, which is a view controller.  The CLI
/// never prompts: it carries what it was given and nothing more.  It is an operation
/// because that is how MADOperationRefresh looks for credentials -- it inspects its
/// own dependencies for the protocol.
@interface MADCLICredentialsOperation : MADOperation <MADOperationHoldsCredentialsProtocol>
@property (nonatomic, strong) MADCredential *credentials;
@end

@implementation MADCLICredentialsOperation
- (BOOL)isAsynchronous { return YES; }
- (void)execute { [self finish]; }
- (BOOL)gotCredentials { return self.credentials != nil; }
- (BOOL)manuallyInputtedCredentials { return NO; }
@end

@interface MADCLIDocument ()
@property (nonatomic, strong) id <MADDocumentDataProtocol> document;
@end

@implementation MADCLIDocument

+ (instancetype)documentWithURL:(NSURL *)url error:(NSError **)error {

	id <MADDocumentDataProtocol> document = nil;

#if __APPLE__
	MADocument *appDocument = [[MADocument alloc] initWithFileURL: url];
	document = appDocument;

	__block BOOL finished = NO;
	__block BOOL success = NO;
	[appDocument openWithCompletionHandler: ^(BOOL opened) {
		success = opened;
		finished = YES;
	}];

	// UIDocument opens asynchronously and delivers its completion on the main queue,
	// so the run loop has to turn while we wait.  A CLI has no other use for it.
	while (!finished) {
		@autoreleasepool {
			[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
									 beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
		}
	}

	if (!success) {
		if (error) *error = MADCLIDocumentError([NSString stringWithFormat: @"Could not open %@.", url.lastPathComponent]);
		return nil;
	}
#else
	document = [MADHeadlessDocument documentWithContentsOfURL: url error: error];
	if (document == nil) {
		return nil;
	}
#endif

	document.limitResultsDesignMode = NO;

	MADCLIDocument *cli = [[MADCLIDocument alloc] init];
	cli.document = document;
	return cli;
}

#pragma mark - Refresh

- (BOOL)refreshWithCredentials:(MADCredential *)credentials error:(NSError **)error {

	id <MADDocumentDataProtocol> document = self.document;
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;

	MADOperationRefreshInitializeMainDataTable *initializeTable =
		[[MADOperationRefreshInitializeMainDataTable alloc] initWithDocument: document];

	MADOperationRefreshInitialize *initialize =
		[[MADOperationRefreshInitialize alloc] initWithDocument: document];
	[initialize addDependency: initializeTable];

	MADOperationRefresh *refresh = [[MADOperationRefresh alloc] initWithDocument: document];
	[refresh addDependency: initializeTable];
	[refresh addDependency: initialize];

	[queue addOperation: initializeTable];
	[queue addOperation: initialize];

	if (credentials != nil) {
		MADCLICredentialsOperation *holder = [[MADCLICredentialsOperation alloc] init];
		holder.credentials = credentials;
		[refresh addDependency: holder];
		[queue addOperation: holder];
	}

	[queue addOperation: refresh];

	while (queue.operationCount > 0) {
		@autoreleasepool {
			[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
									 beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
		}
	}

	// The credentials holder is not an NSOperation, so it cannot sit in the queue
	// directly; see the note on MADCLICredentialsOperation above.
	if (refresh.errors.count > 0) {
		if (error) *error = refresh.errors.firstObject;
		return NO;
	}
	return YES;
}

@end
