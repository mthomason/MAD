//
//  MADCreateDocumentOperationAddConnection.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationCreateDocumentAddConnection.h"
#import "MADOperationCreateDocumentCreateDocument.h"
#import "madlog.h"

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADErrorContainer.h>

#import <MAD/MADocument.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>

@interface MADOperationCreateDocumentAddConnection ()

	@property (nonatomic, assign) BOOL success;
	@property (nonatomic, copy) MADDatabaseConnection *databaseConnection;

@end

@implementation MADOperationCreateDocumentAddConnection

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
	MADocument *document = nil;
	NSArray <NSOperation *> *dependencies = self.dependencies;
	for (NSOperation *dependency in dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationCreateDocumentProtocol)]) {
			document = ((id <MADOperationCreateDocumentProtocol>)dependency).document;
			break;
		}
	}
	[document activeDocumentModel];
	self.success = YES;
	[self finish];
}

@end
