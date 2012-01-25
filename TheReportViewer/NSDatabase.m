//
//  NSDatabase.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSDatabase.h"
#import "Constants.h"
#import "UIManagedDocumentQuery.h"
#import "NSFileManager+Common.h"

@implementation NSDatabase
@synthesize managedDocumentQuery = _managedDocumentQuery;

- (void)dealloc {
    [_managedDocumentQuery release];
    [super dealloc];
}

//Init with url. Open the file at that url.
- (id)initExistingFileWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        
    }
    return self;
}

//Init with new file name. Create and open the file at that url.
- (id)initNewFileWithName:(NSString *)name completion:(void (^)(BOOL success))completion {

    self = [super init];
    if (self) {

        NSURL *baseUrl = [[[NSFileManager applicationDocumentsDirectoryUrl]
                           URLByAppendingPathComponent: name] retain];
        NSURL *applicationFileUrlWithExtention = [[baseUrl URLByAppendingPathExtension: SCHEMA_PATH_EXTENSION] retain];
        
        NSFileManager *defaultFileManager = [NSFileManager defaultManager];
        NSInteger ctr = 0;
        BOOL isDirectory;
        while ([defaultFileManager fileExistsAtPath:[applicationFileUrlWithExtention absoluteString] isDirectory:&isDirectory]) {
            
            [applicationFileUrlWithExtention release];
            applicationFileUrlWithExtention = [[[baseUrl URLByAppendingPathComponent:[NSString stringWithFormat:@" %d", ctr]]
                                                URLByAppendingPathExtension: SCHEMA_PATH_EXTENSION] retain];
            ctr++;
        }
        [baseUrl release];
        
        UIManagedDocumentQuery *document = [[UIManagedDocumentQuery alloc] initWithFileURL:applicationFileUrlWithExtention];
        [self setManagedDocumentQuery: document];
        [document release];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[applicationFileUrlWithExtention path]]) {
            [[self managedDocumentQuery] saveToURL:applicationFileUrlWithExtention forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                completion(success);
            }];
        } else if ([[self managedDocumentQuery] documentState] == UIDocumentStateClosed) {
            [[self managedDocumentQuery] openWithCompletionHandler: ^(BOOL success) {
                completion(success);
            }];
        } else if ([[self managedDocumentQuery] documentState] == UIDocumentStateNormal) {
            completion(YES);
        }

        [applicationFileUrlWithExtention release];
    }
    return self;
}

#pragma mark - Public Actions

- (void)openFile:(NSURL *)url completion:(void (^)(BOOL success))completion {
    UIManagedDocumentQuery *document = [[UIManagedDocumentQuery alloc] initWithFileURL:url];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        [document openWithCompletionHandler:^(BOOL success) {
            completion(success);
        }];
    } else {
        [document saveToURL:url forSaveOperation:UIDocumentSaveForCreating
          completionHandler:^(BOOL success) {
              completion(success);
          }];
    }
    [document release];
}

- (void)save {
    [[self managedDocumentQuery] saveToURL: [[self managedDocumentQuery] fileURL] forSaveOperation: UIDocumentSaveForOverwriting
      completionHandler:^(BOOL success) {
          //completion(success);
      }];
}

@end