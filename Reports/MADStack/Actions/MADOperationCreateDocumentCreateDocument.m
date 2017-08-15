//
//  MADCreateDocumentOperationCreateDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationCreateDocumentCreateDocument.h"
#import <os/log.h>
#import <MAD/MADDocumentProtocol.h>

#import <MAD/MADocument.h>
#import <MAD/MADCredential.h>
#import <MAD/MTDatabase.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADDatabaseConnection.h>

#import "MADOperationUniqueUrlForFilename.h"
#import "MADOperationPromptErrorProtocol.h"

@interface MADOperationCreateDocumentCreateDocument ()
    <MADocumentDelegate>
    
    @property (nonatomic, readwrite, strong) MADocument *document;

    @property (nonatomic, readwrite, copy) NSURL *url;
    @property (nonatomic, readwrite, copy) MADCredential *credentials;
    @property (nonatomic, readwrite, copy) MADDatabaseConnection *databaseConnection;

@end

@implementation MADOperationCreateDocumentCreateDocument

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection {
    if (self = [super init]) {
        self.databaseConnection = databaseConnection.copy;
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
    os_log_info(OS_LOG_DEFAULT, "Begin %s", NSStringFromClass(self.class).UTF8String);
    if (self.cancelled) return [self finish];

    if (!_url) {
        
        for (NSOperation *dependency in self.dependencies) {
            if ([dependency conformsToProtocol:@protocol(MADOperationUniqueUrlForFilenameProtocol)]) {
                _url = ((NSObject <MADOperationUniqueUrlForFilenameProtocol> *)dependency).uniqueUrl.copy;
            }
        }
        
    }
    
    if (self.cancelled) return [self finish];

    //Create MADocument File and Remove Cache
    MADocument *document = [[MADocument alloc] initWithFileURL: self.url andDatabaseConnection:self.databaseConnection];

    document.documentDelegate = self;
    [document archiveAndRemoveFileWrapper];
    self.document = document;
    
    if (self.cancelled) return [self finish];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self.document saveToURL: self.url
                forSaveOperation: UIDocumentSaveForCreating
               completionHandler: ^(BOOL success) {
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
