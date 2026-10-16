//
//  MADCreateDocumentOperationFirstTimeSetup.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/31/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//


#import "MADOperationCreateDocumentFirstTimeSetup.h"
#import "MADOperationCreateDocumentCreateDocument.h"

#import <MADAPI/MADDatabaseConnection.h>

#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqDocumentSection.h>

#import <MADFoundation/madlog.h>

@interface MADOperationCreateDocumentFirstTimeSetup ()

	@property (nonatomic, assign) BOOL success;
	@property (nonatomic, copy) MADDatabaseConnection *databaseConnection;

@end

// The portable store context is main-queue-owned.  Marshal store reads onto
// the main queue (inline when already there) rather than taking a lock in
// every accessor.  See BUGS.md "The refresh path reads the shared store
// context from operation-queue threads".
static void MADOperationCreateDocumentFirstTimeSetupRunOnMain(dispatch_block_t block) {
	if ([NSThread isMainThread]) block();
	else dispatch_sync(dispatch_get_main_queue(), block);
}

@implementation MADOperationCreateDocumentFirstTimeSetup

- (void)dealloc { }

- (instancetype)init {
	return [self initWithDatabaseConnection:nil];
}

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection {
	if (self = [super init]) {
		self.databaseConnection = databaseConnection.copy;
		self.success = NO;
	}
	return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	if (self.cancelled) return [self finish];

	MADocument * document = nil;
	NSArray <NSOperation *> *dependencies = self.dependencies;
	for (NSOperation *dependency in dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationCreateDocumentProtocol)]) {
			document = ((id <MADOperationCreateDocumentProtocol>)dependency).document;
			break;
		}
	}
	
	if (self.cancelled) return [self finish];

	// Creating the document object and saving is small enough to marshal onto
	// main rather than lock the store's accessors.
	__block BOOL success = NO;
	__block NSError *saveError = nil;
	MADOperationCreateDocumentFirstTimeSetupRunOnMain(^{
		RptqStoreContext *context = document.storeContext;
		success = [RptqDocument newDocumentForManagedObjectContext: context] != nil;
		success = success && [context save:&saveError];
	});
	if (!success && saveError != nil) {
		os_log_error(OS_LOG_DEFAULT, "Error saving the portable store: %@", saveError.localizedDescription);
	}
	[document updateChangeCount: UIDocumentChangeDone];

	[self finish];
}

@end
