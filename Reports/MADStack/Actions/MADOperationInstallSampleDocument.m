//
//  MADOperationInstallSampleDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationInstallSampleDocument.h"

@interface MADOperationInstallSampleDocument ()

@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *fileExtension;
@property (nonatomic, strong) NSString *groupIdentifier;
@property (nonatomic, strong) NSString *installFlag;

@end

@implementation MADOperationInstallSampleDocument

- (instancetype)initWithFilename:(NSString *)filename fileExtension:(NSString *)fileExtension groupIdentifier:(NSString *)groupIdentifier installFlag:(NSString *)installFlag {
    if (self = [super init]) {
        
        NSString *fn = [NSString stringWithString:filename];
        self.filename = fn;
        
        NSString *fe = [NSString stringWithString:fileExtension];
        self.fileExtension = fe;
        
        NSString *gi = [NSString stringWithString:groupIdentifier];
        self.groupIdentifier = gi;
        
        NSString *ii = [NSString stringWithString:installFlag];
        self.installFlag = ii;
        
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
