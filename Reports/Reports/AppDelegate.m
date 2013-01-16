//
//  AppDelegate.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate()

@property (retain) MNSDocumentReport *documentReport;
@property (retain) UIManagedDocumentReport *managedDocumentQuery;
@property (retain) UIManagedDocumentPreferencesApplication *applicationPreferences;
@property (retain) UIManagedDocumentPreferencesUser *openReport;

@end

@implementation AppDelegate

void uncaughtExceptionHandler(NSException *exception);
void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"%@", exception);
}

+ (MNSDocumentReport *)activeDocument {
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return [appDelegate documentReport];
}

+ (void)setActiveDocument:(MNSDocumentReport *)activeDocument {
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return [appDelegate setDocumentReport:activeDocument];
}

- (void)dealloc {
    [_documentReport release];
    [_applicationPreferences release];
    [_managedDocumentQuery release];
    [_openReport release];
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    return YES;
}
			
- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application { }

- (void)applicationDidBecomeActive:(UIApplication *)application { }

- (void)applicationWillTerminate:(UIApplication *)application { }

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return   [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ?
                    UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
}

/*
#pragma mark - Persistent Store Coordinator

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    
    if (![self persistentStoreCoordinatorMain]) {
        NSError *error;
        
        NSPersistentStoreCoordinator *ps = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]]; 
        [self setPersistentStoreCoordinatorMain: ps];
        [ps release];
        
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
        
        NSArray *types = [[NSArray alloc] initWithObjects:PRESISTENT_STORE_TYPE_MYSQL, nil]; 

        for (NSString * type in types) {
            if (![[self persistentStoreCoordinatorMain] addPersistentStoreWithType:type configuration:nil URL:dataStoreURL options:options error:&error]){
                if ([error code] == 134100) {
                    //If we failed with an incorrect data model error then pass the version identifiers of the store to the delegate to decide what to do next
                    if ([[self delegate] respondsToSelector:@selector(coreDataManager:encounteredIncorrectModelWithVersionIdentifiers:)]) {
                        persistentStoreCoordinator = nil;
                        NSDictionary *metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:initialType URL:dataStoreURL error:&error];
                        [[self delegate] coreDataManager:self encounteredIncorrectModelWithVersionIdentifiers:[metadata objectForKey:NSStoreModelVersionIdentifiersKey]];
                    } else {
                        //FIXME: Show error!!!
                        //[[UIApplication sharedApplication] presentError:error];
                    }
                }
            }    
        }
    }

    return persistentStoreCoordinator;
}*/

#pragma mark - Actions


- (NSURL *)createAndOpenNewDocumentNamed:(NSString *)name withPathExtention:(NSString *)extention {
    
    NSURL *baseUrl = [[[NSFileManager applicationDocumentsDirectoryUrl]
                      URLByAppendingPathComponent: name] retain];
    NSURL *applicationFileUrlWithExtention = [[baseUrl URLByAppendingPathExtension: @"trvp"] retain];

    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    NSInteger ctr = 0;
    BOOL isDirectory;
    while ([defaultFileManager fileExistsAtPath:[applicationFileUrlWithExtention absoluteString] isDirectory:&isDirectory]) {

        [applicationFileUrlWithExtention release];
        applicationFileUrlWithExtention = [[[baseUrl URLByAppendingPathComponent:[NSString stringWithFormat:@" %d", ctr]]
                                            URLByAppendingPathExtension: @"trvp"] retain];
        ctr++;
    }
    [baseUrl release];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[applicationFileUrlWithExtention path]]) {
        [[self openReport] openWithCompletionHandler: ^(BOOL success) {
            if (success) {  //File opened
                NSLog(@"Final Path: %@", [[[self openReport] fileURL] absoluteString]);
                switch ([[self openReport] documentState]) {
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
        [[self openReport] saveToURL: [[self openReport] fileURL]
                                forSaveOperation: UIDocumentSaveForCreating
                               completionHandler: ^(BOOL success) {
                                   if (success) {  //File created for the first time evar
                                       switch ([[self openReport] documentState]) {
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
    return [applicationFileUrlWithExtention autorelease];
}

@end