//
//  AppDelegate.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "NSFileManager+Common.h"

@implementation AppDelegate

@synthesize window = _window;

@synthesize applicationPreferences = _applicationPreferences;
@synthesize openReport = _openReport;

- (void)dealloc {
    [_applicationPreferences release];
    [_openReport release];
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //NSLog(@"applicationDocumentsDirectory: %@", [NSFileManager applicationDocumentsDirectory]);
    
    NSLog(@"contentsOfDocumentsDirectory: %@", [NSFileManager contentsOfDocumentsDirectory]);

    
    //Open or create the applications settings file.
    
    NSURL *applicationFileUrlWithExtention = [[[[NSFileManager applicationDocumentsDirectoryUrl]
                                                URLByAppendingPathComponent: @"ApplicationPreferences"]
                                                    URLByAppendingPathExtension: @"trvp"] retain];
        
    UIManagedDocumentTrvApplicationData *managedDocument = [[UIManagedDocumentTrvApplicationData alloc] initWithFileURL:applicationFileUrlWithExtention];
    [self setApplicationPreferences: managedDocument];
    [managedDocument release];

    [[self applicationPreferences] setPersistentStoreOptions: [NSDictionary dictionaryWithObjectsAndKeys:
                                                               [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                                               [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil]];
    
    NSLog(@"Path: %@", [applicationFileUrlWithExtention path]);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[applicationFileUrlWithExtention path]]) {
        [[self applicationPreferences] openWithCompletionHandler: ^(BOOL success) {
            if (success) {  //File opened
                NSLog(@"Final Path: %@", [[[self applicationPreferences] fileURL] absoluteString]);
                switch ([[self applicationPreferences] documentState]) {
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
        [[self applicationPreferences] saveToURL: [[self applicationPreferences] fileURL]
                                forSaveOperation: UIDocumentSaveForCreating
                               completionHandler: ^(BOOL success) {
                                   if (success) {  //File created for the first time evar
                                       switch ([[self applicationPreferences] documentState]) {
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
    [applicationFileUrlWithExtention release];
    
    return YES;
}
			
- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

#pragma mark -

- (void)openReport:(NSURL *)url {
    UIManagedDocument *document = [[UIManagedDocument alloc] initWithFileURL:url];
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

- (NSURL *)createAndOpenNewDocumentNamed:(NSString *)name withPathExtention:(NSString *)extention {
    NSURL *result = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    result = [result URLByAppendingPathComponent: name];
    result = [result URLByAppendingPathExtension: extention];
    return result;
}

@end