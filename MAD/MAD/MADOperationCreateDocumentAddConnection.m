//
//  MADCreateDocumentOperationAddConnection.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationCreateDocumentAddConnection.h"

#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MADDatabaseConnection.h>
#import <MAD/MADErrorContainer.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>

#import "MADOperationCreateDocumentCreateDocument.h"

#import <os/log.h>

@interface MADOperationCreateDocumentAddConnection ()

    @property (nonatomic, assign) BOOL success;
    @property (nonatomic, copy) MADDatabaseConnection *databaseConnection;

@end

@implementation MADOperationCreateDocumentAddConnection

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

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
    os_log_info(OS_LOG_DEFAULT, "Begin %s", NSStringFromClass(self.class).UTF8String);

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
