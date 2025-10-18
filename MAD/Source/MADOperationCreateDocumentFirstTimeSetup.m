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
#import <MAD/RptqDocument+extras.h>
#import <MAD/RptqDatabase+extras.h>
#import <MAD/RptqQuery+extras.h>
#import <MAD/RptqDocumentSection.h>

#import <os/log.h>
#import <CoreData/NSManagedObjectContext.h>

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
			NSError *error = nil;
			success = [private save:&error];
			if (!success && error != nil) {
				os_log_error(OS_LOG_DEFAULT, "Error saving managed object: %@", error.localizedDescription);
			}
		} else {
			NSError *error = nil;
			success = [private save:&error];
			if (!success && error != nil) {
				os_log_error(OS_LOG_DEFAULT, "Error saving managed object: %@", error.localizedDescription);
			}
		}
	}];
	[document updateChangeCount: UIDocumentChangeDone];

	[self finish];
}

@end
