//
//  MADInstallOperationSampleDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADInstallOperationSampleDocument.h"
#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSURL.h>
#import <MADFileManager/MADFileManager.h>

@interface MADInstallOperationSampleDocument ()

@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *fileExtension;
@property (nonatomic, copy) NSString *groupIdentifier;
@property (nonatomic, copy) NSString *installFlag;

@end

@implementation MADInstallOperationSampleDocument

- (instancetype)initWithFilename:(NSString *)filename fileExtension:(NSString *)fileExtension groupIdentifier:(NSString *)groupIdentifier installFlag:(NSString *)installFlag {
    if (self = [super init]) {
        
        NSString * __autoreleasing fn = [[NSString alloc] initWithString:filename];
        self.filename = fn;
        
        NSString * __autoreleasing fe = [[NSString alloc] initWithString:fileExtension];
        self.fileExtension = fe;
        
        NSString * __autoreleasing gi = [[NSString alloc] initWithString:groupIdentifier];
        self.groupIdentifier = gi;
        
        NSString * __autoreleasing ii = [[NSString alloc] initWithString:installFlag];
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
