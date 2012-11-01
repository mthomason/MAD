//
//  NSDatabase.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSDatabase.h"

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
#warning Not implemented
    }
    return self;
}

//Init with new file name. Create and open the file at that url.
- (id)initNewFileWithName:(NSString *)name completion:(void (^)(BOOL success))completion {

    self = [super init];
    if (self) {
        NSFileManager *defaultFileManager = [NSFileManager defaultManager];
        NSURL *baseUrl = [[[NSFileManager applicationDocumentsDirectoryUrl]
                           URLByAppendingPathComponent: name] retain];
        NSURL *applicationFileUrlWithExtention = [[baseUrl URLByAppendingPathExtension: SCHEMA_PATH_EXTENSION] retain];
        [baseUrl release];
        
        NSInteger ctr = 0;
        while ([defaultFileManager fileExistsAtPath:[applicationFileUrlWithExtention path]]) {            
            [applicationFileUrlWithExtention release];
            
            NSURL *baseUrlFormatted = [[[NSFileManager applicationDocumentsDirectoryUrl]
                                        URLByAppendingPathComponent: [name stringByAppendingFormat:@" %d", ctr]] retain];

            
            applicationFileUrlWithExtention = [[baseUrlFormatted
                                                URLByAppendingPathExtension: SCHEMA_PATH_EXTENSION] retain];
            [baseUrlFormatted release];
            ctr++;
            NSLog(@"While file exist %@", applicationFileUrlWithExtention);
        }
        
        UIManagedDocumentQuery *document = [[UIManagedDocumentQuery alloc] initWithFileURL:applicationFileUrlWithExtention];
        [self setManagedDocumentQuery: document];
        [document release];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[applicationFileUrlWithExtention path]]) {
            [[self managedDocumentQuery] saveToURL:applicationFileUrlWithExtention forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                NSLog(@"File saved, or not?");
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

- (void)queryDatabaseForManagedObjectContext: (NSManagedObjectContext *)moc
                       withCompletionHandler: (void (^)(NSArray *results, BOOL success))completion {
    completion([NSArray array], YES);
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