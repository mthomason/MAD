//
//  MADCreateDocumentOperationCreateDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCreateDocumentOperationCreateDocument.h"
#import <MAD/MADocument.h>
#import <MAD/MADCredential.h>

@interface MADCreateDocumentOperationCreateDocument ()
    <MADocumentDelegate>
    
    @property (nonatomic, readwrite, strong) MADocument *document;

    @property (nonatomic, readwrite, copy) NSURL *url;
    @property (nonatomic, readwrite, copy) MADCredential *credentials;

@end

@implementation MADCreateDocumentOperationCreateDocument

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    if (self.credentials == nil) {

        NSArray<NSOperation *> *dependencies = self.dependencies;
        for (NSOperation *dependency in dependencies) {
        
            if ([dependency conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)]) {
            
                id <MADOperationHoldsCredentialsProtocol> holdCredentials = (id <MADOperationHoldsCredentialsProtocol>)dependency;
                if ([holdCredentials gotCredentials]) {
                    self.credentials = [holdCredentials credentials];
                }

            }
            
        }
        
    }
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
    
    //Create MADocument File and Remove Cache
    MADocument *document = [[MADocument alloc] initWithFileURL: self.url];
    document.documentDelegate = self;
    [document removeGuts];
    self.document = document;
    
    [self finish];
    
}

@end
