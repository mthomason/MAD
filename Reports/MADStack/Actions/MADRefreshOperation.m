//
//  MADRefreshOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADRefreshOperation.h"
#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTDataTableFast.h>
#import <MAD/MTQuery.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MADConstants.h>
#import <Foundation/NSError.h>
#import <Foundation/NSURL.h>
#import <CoreData/NSManagedObjectContext.h>
#import "MADRefreshOperationInitalize.h"
#import <MAD/MADCredential.h>
#import <MAD/MTQueryFull.h>

static const short errCache = 2;

@interface MADRefreshOperation ()

    @property (nonatomic, weak) MADocument *document;

@end

@implementation MADRefreshOperation

- (void)dealloc {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithDocument:(MADocument *)document {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    if (self = [super init]) {
        _document = document;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);

    MADocument *document = self.document;
    MADCredential *credientals = nil;
    
    if ([document.database.databaseConnection requiresCredientals]) {

        for (NSOperation *dependency in self.dependencies) {
            if ([dependency conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)] &&
                ((id <MADOperationHoldsCredentialsProtocol>)dependency).gotCredentials) {
                credientals = ((id <MADOperationHoldsCredentialsProtocol>)dependency).credentials;
            }
        }
        
        if (credientals == nil) {
            NSError *error = [NSError errorWithDomain:@"MADCache" code:errCache + 1 userInfo:nil];
            [self finishWithError:error];
            return;
        }
    }
    
    NSError * __autoreleasing eerror = NULL;
    MTDatabaseConnection *connectionSettings = [document.database databaseConnection];
    id dbconn = [document.database connectWithConnection:connectionSettings credentals:credientals];
    
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
    private.parentContext = document.managedObjectContext;

    __block NSString *queryString = nil;
    MTQueryFull *query = document.mainQuery;
    [private performBlockAndWait:^{
        NSError *sqlError = NULL;
        queryString = [query getSqlWithManagedObjectContext:private error:&sqlError];
    }];
    
    //NSLog(@"QueryString: %@", queryString);
    
    NSError *executeError = NULL;
    BOOL success = [document.database executeSql:queryString fieldKeys:query.fieldKeys onConnection:dbconn intoResultTable:document.mainDataTable withError:&executeError];

    if (!success) {
        NSLog(@"Failed to execute sql!");
        NSError *error = eerror;
        [self finishWithError:error];
        return;
    }

    success = [document.mainDataTable cacheWithUrl:document.urlDataTableCache];
    
    if (!success) {
        NSError *error = [NSError errorWithDomain:@"MADCache" code:errCache userInfo:nil];
        [self finishWithError:error];
        return;
    }

    [self finish];
}

@end
