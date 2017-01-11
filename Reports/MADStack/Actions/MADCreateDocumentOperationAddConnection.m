//
//  MADCreateDocumentOperationAddConnection.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCreateDocumentOperationAddConnection.h"

#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MADErrorContainer.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>

#import "MADCreateDocumentOperationCreateDocument.h"

@interface MADCreateDocumentOperationAddConnection ()

    @property (nonatomic, assign) BOOL success;
    @property (nonatomic, strong) MTDatabaseConnection *databaseConnection;

@end

@implementation MADCreateDocumentOperationAddConnection

- (void)dealloc {

}

- (instancetype)init {
    return [self initWithDatabaseConnection:nil];
}

- (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)databaseConnection {
    if (self = [super init]) {
        self.databaseConnection = databaseConnection;
        self.success = NO;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    
    MADocument *document = nil;
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
    
        if ([dependency conformsToProtocol:@protocol(MADCreateDocumentOperationCreateDocumentProtocol)]) {
            document = ((id <MADCreateDocumentOperationCreateDocumentProtocol>)dependency).document;
            break;
        }
        
    }

    [document activeDocumentModel];
    MTDatabase *database = [MTDatabase newDatabaseWithConnection:self.databaseConnection];

    if (database) {
    
        document.database = database;
        self.success = YES;
        [self finish];

    } else {

        self.success = NO;
        NSString *domain = NSStringFromClass(self.class);
        NSError *error = [NSError errorWithDomain:domain code:289 userInfo:nil];
        [self finishWithError:error];
    
    }
}

@end
