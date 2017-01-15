//
//  MADOperationInstallSampleDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationInstallSampleDocument.h"
#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSURL.h>
#import <MADFoundation/MADURL.h>

@interface MADOperationInstallSampleDocument ()

    @property (nonatomic, copy) NSString *filename;
    @property (nonatomic, copy) NSString *fileExtension;
    @property (nonatomic, copy) NSString *groupIdentifier;
    @property (nonatomic, copy) NSString *installFlag;

@end

@implementation MADOperationInstallSampleDocument

- (void)dealloc {
    //NSLog(@"dealloc MADOperationInstallSampleDocument");
}

- (instancetype)initWithFilename:(NSString *)filename fileExtension:(NSString *)fileExtension
                 groupIdentifier:(NSString *)groupIdentifier installFlag:(NSString *)installFlag {

    if (self = [super init]) {
        
        _filename = filename.copy;
        _fileExtension = fileExtension.copy;
        _groupIdentifier = groupIdentifier.copy;
        _installFlag = installFlag.copy;
        
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {

    BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:_installFlag];
    if (!installed) {
        
    
        NSURL *localDocumentsDirectory;
        localDocumentsDirectory = [MADURL newURLLocalDocumentsDirectoryForGroupIdentifier:_groupIdentifier];
        NSURL *destination = [localDocumentsDirectory URLByAppendingPathComponent: _filename
                                                                      isDirectory: NO];
        
        // !!!: Do an extra check to hanle the case of upgrades.
        BOOL isDirectory;
        NSString *path = destination.path;
        installed = [[NSFileManager defaultManager] fileExistsAtPath: path
                                                         isDirectory: &isDirectory];
        
        if (!installed) {
            NSURL *origin = [self resourceUrl];
            NSError *error;
            destination = [destination URLByAppendingPathExtension: _fileExtension];
            installed = [[NSFileManager defaultManager] copyItemAtURL: origin
                                                                toURL: destination
                                                                error: &error];
        }
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setBool:installed forKey:_installFlag];
    }
    [self finish];
}

- (NSURL *)resourceUrl {
    return [[NSBundle mainBundle] URLForResource: _filename
                                   withExtension: _fileExtension];
}

@end
