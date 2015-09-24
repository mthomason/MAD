//
//  MADOperationInstallSampleDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationInstallSampleDocument.h"

@interface MADOperationInstallSampleDocument ()

@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *fileExtension;
@property (nonatomic, copy) NSString *groupIdentifier;
@property (nonatomic, copy) NSString *installFlag;

@end

@implementation MADOperationInstallSampleDocument

- (instancetype)initWithFilename:(NSString *)filename fileExtension:(NSString *)fileExtension groupIdentifier:(NSString *)groupIdentifier installFlag:(NSString *)installFlag {
    if (self = [super init]) {
        self.filename = filename.copy;
        self.fileExtension = fileExtension.copy;
        self.groupIdentifier = groupIdentifier.copy;
        self.installFlag = installFlag.copy;
    }
    return self;
}

- (void)main {
    BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:self.installFlag];
    if (!installed) {
        
        NSURL *destinationDirectory = [[NSFileManager defaultManager] localDocumentsDirectoryForGroupIdentifier:self.groupIdentifier];
        NSURL *destination = [destinationDirectory URLByAppendingPathComponent: self.filename isDirectory: NO];
        
        // !!!: Do an extra check to hanle the case of upgrades.
        BOOL isDirectory;
        installed = [[NSFileManager defaultManager] fileExistsAtPath:destination.path isDirectory:&isDirectory];
        
        if (!installed) {
            NSURL *origin = [[NSBundle mainBundle] URLForResource: self.filename withExtension: self.fileExtension];
            NSError *error;
            destination = [destination URLByAppendingPathExtension:self.fileExtension];
            installed = [[NSFileManager defaultManager] copyItemAtURL:origin toURL:destination error:&error];
        }
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setBool:installed forKey:self.installFlag];
    }
}

@end
