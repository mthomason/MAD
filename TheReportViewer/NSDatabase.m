//
//  NSDatabase.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDatabase.h"
#import "UIManagedDocumentQuery.h"
#import "NSFileManager+Common.h"

@implementation NSDatabase
@synthesize managedDocumentQuery = _managedDocumentQuery;

- (void)dealloc {
    [_managedDocumentQuery release];
    [super dealloc];
}

//Init with url. Open the file at that url.
- (id)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        
    }
    return self;
}

//Init with new file name. Create and open the file at that url.
- (id)initWithFileName:(NSString *)name {
    self = [super init];
    if (self) {
        
        NSURL *baseUrl = [[[NSFileManager applicationDocumentsDirectoryUrl]
                           URLByAppendingPathComponent: name] retain];
        NSURL *applicationFileUrlWithExtention = [[baseUrl URLByAppendingPathExtension: @"trvq"] retain];
        
        NSFileManager *defaultFileManager = [NSFileManager defaultManager];
        NSInteger ctr = 0;
        BOOL isDirectory;
        while ([defaultFileManager fileExistsAtPath:[applicationFileUrlWithExtention absoluteString] isDirectory:&isDirectory]) {
            
            [applicationFileUrlWithExtention release];
            applicationFileUrlWithExtention = [[[baseUrl URLByAppendingPathComponent:[NSString stringWithFormat:@" %d", ctr]]
                                                URLByAppendingPathExtension: @"trvq"] retain];
            ctr++;
        }
        [baseUrl release];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[applicationFileUrlWithExtention path]]) {
            [[self managedDocumentQuery] openWithCompletionHandler: ^(BOOL success) {
                if (success) {  //File opened
                    NSLog(@"Final Path: %@", [[[self managedDocumentQuery] fileURL] absoluteString]);
                    switch ([[self managedDocumentQuery] documentState]) {
                        case UIDocumentStateNormal: {
                            //NSManagedObjectContext *context = self.applicationPreferences.managedObjectContext;
                            
                            break;
                        }
                        default:
                            break;
                    }
                } else {
                    NSLog(@"couldn’t open document at %@", @"");//applicationFileUrlWithExtention);
                }
            }];
        } else {
            [[self managedDocumentQuery] saveToURL: [[self managedDocumentQuery] fileURL]
                                  forSaveOperation: UIDocumentSaveForCreating
                                 completionHandler: ^(BOOL success) {
                                     if (success) {  //File created for the first time evar
                                         switch ([[self managedDocumentQuery] documentState]) {
                                             case UIDocumentStateNormal: {
                                                 //NSManagedObjectContext *context = self.applicationPreferences.managedObjectContext;
                                                 break;
                                             }
                                             default:
                                                 break;
                                         }
                                     } else {
                                         NSLog(@"Couldn’t create document at %@", @"");//applicationFileUrlWithExtention);
                                     }
                                 }];
        }
        
        [applicationFileUrlWithExtention autorelease];
        //return applicationFileUrlWithExtention;        
        
    }
    return self;
}

#pragma mark - Public Actions

- (void)openFile:(NSURL *)url {
    UIManagedDocumentQuery *document = [[UIManagedDocumentQuery alloc] initWithFileURL:url];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        [document openWithCompletionHandler:^(BOOL success) {
            if (success) {
                //[self documentIsReady];
            } else {
                NSLog(@"couldn’t open document at %@", url);
            }
        }];
    } else {
        [document saveToURL:url forSaveOperation:UIDocumentSaveForCreating
          completionHandler:^(BOOL success) {
              if (success) NSLog(@"New file created"); //[self documentIsReady];
              else NSLog(@"couldn’t create document at %@", url);
          }];
    }
    [document release];
    // can’t do anything with the document yet (do it in do
}

@end