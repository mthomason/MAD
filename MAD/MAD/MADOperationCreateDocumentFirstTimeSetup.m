//
//  MADCreateDocumentOperationFirstTimeSetup.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/31/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import <os/log.h>
#import <CoreData/NSManagedObjectContext.h>

#import <MADAPI/MADDatabaseConnection.h>

#import <MAD/MADocument.h>
#import <MAD/RptqDocument+extras.h>
#import <MAD/RptqDatabase+extras.h>
#import <MAD/RptqQuery+extras.h>
#import <MAD/RptqDocumentSection.h>
#import "MADOperationCreateDocumentFirstTimeSetup.h"
#import "MADOperationCreateDocumentCreateDocument.h"

@interface MADOperationCreateDocumentFirstTimeSetup ()

	@property (nonatomic, assign) BOOL success;
	@property (nonatomic, copy) MADDatabaseConnection *databaseConnection;

@end

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

	NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	private.parentContext = document.managedObjectContext;
	[private performBlockAndWait:^{
		BOOL success = [RptqDocument newDocumentForManagedObjectContext: private] != nil;
		if (success) {
			NSError * __autoreleasing error = NULL;
			if (!(success = [private save:&error])) {
				os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
			}
		} else {
			NSError * __autoreleasing error = NULL;
			if (!(success = [private save:&error])) {
				os_log_info(OS_LOG_DEFAULT, "Error saving managed object: %s", error.localizedDescription.UTF8String);
			}
		}
	}];
	[document updateChangeCount: UIDocumentChangeDone];

	[self finish];
}

@end
