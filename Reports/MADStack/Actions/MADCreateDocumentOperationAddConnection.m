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
#import <MAD/MADNotificationProgress.h>
#import <MAD/MADErrorContainer.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>

#import "MADCreateDocumentOperationCreateDocument.h"

@interface MADCreateDocumentOperationAddConnection ()

    @property (nonatomic, assign) bool success;
    @property (nonatomic, strong) MTDatabaseConnection *databaseConnection;

@end

@implementation MADCreateDocumentOperationAddConnection

- (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)databaseConnection {
    if (self = [super init]) {
        self.databaseConnection = databaseConnection;
        self.success = false;
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

    RptqDocument *rptqDocument = [document activeDocumentModel];
    MTDatabase *database = [MTDatabase databaseFactory:self.databaseConnection];

    if (database) {
        [document setMainDatabase:database];
        
        [rptqDocument addDatabase: document.mainDatabase status: ^(NSString *message, float progress) {
        
            [[MADNotificationProgress sharedObject] updateProgressWithMessage:message progress:progress];
            
        } completion:^(BOOL success, MADErrorContainer *errorContainer) {
        
            self.success = success;
            if (success) {
                [self finish];
            } else {
                [self finish:[errorContainer allObjects]];
            }
            
        }];
        
    } else {
        self.success = false;
        NSString *domain = NSStringFromClass(self.class);
        NSError *error = [NSError errorWithDomain:domain code:289 userInfo:nil];
        [self finishWithError:error];
    }

}

@end
