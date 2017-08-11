//
//  MADCreateDocumentOperationCreateDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationCreateDocumentCreateDocument.h"
#import <MAD/MADDocumentProtocol.h>

#import <MAD/MADocument.h>
#import <MAD/MADCredential.h>
#import <MAD/MTDatabase.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>

#import "MADOperationUniqueUrlForFilename.h"

@interface MADOperationCreateDocumentCreateDocument ()
    <MADocumentDelegate>
    
    @property (nonatomic, readwrite, strong) MADocument *document;

    @property (nonatomic, readwrite, copy) NSURL *url;
    @property (nonatomic, readwrite, copy) MADCredential *credentials;
    @property (nonatomic, readwrite, strong) MADDatabaseConnection *databaseConnection;

@end

@implementation MADOperationCreateDocumentCreateDocument

- (void)dealloc {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __PRETTY_FUNCTION__);
}

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection {
    if (self = [super init]) {
        self.databaseConnection = databaseConnection;
    }
    return self;
}

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    //if (self.credentials) {

        NSArray<NSOperation *> *dependencies = self.dependencies;
        for (NSOperation *dependency in dependencies) {
        
            if ([dependency conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)]) {
                id <MADOperationHoldsCredentialsProtocol> holdCredentials = (id <MADOperationHoldsCredentialsProtocol>)dependency;
                if ([holdCredentials gotCredentials]) {
                    self.credentials = [holdCredentials credentials];
                }
            }
        }
    //}
    return self.credentials;
}

- (instancetype)initWithFileUrl:(NSURL *)url {
    if (self = [super init]) {
        _url = url.copy;
        _credentials = nil;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    if (!_url) {
        
        for (NSOperation *dependency in self.dependencies) {
            if ([dependency conformsToProtocol:@protocol(MADOperationUniqueUrlForFilenameProtocol)]) {
                _url = ((NSObject <MADOperationUniqueUrlForFilenameProtocol> *)dependency).uniqueUrl.copy;
            }
        }
        
    }
    
    //Create MADocument File and Remove Cache
    MADocument *document = [[MADocument alloc] initWithFileURL: self.url andDatabaseConnection:self.databaseConnection];

    document.documentDelegate = self;
    [document archiveAndRemoveFileWrapper];
    self.document = document;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self.document saveToURL:self.url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) {
                [self finish];
            } else {
                NSString *domain = NSStringFromClass([self class]);
                NSError *error = [NSError errorWithDomain:domain code:347 userInfo:nil];
                [self finishWithError:error];
            }
        }];
    }];
    
    
}

@end
