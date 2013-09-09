//
//  MNSDocument.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MADocument.h"
#import "MTReportViewerPrintPageRenderer.h"

NSString * const MTDocumentInfoKeyThumbnail = @"thumbnail";
NSString * const MTDocumentInfoKeyThumbnailStandard = @"thumbnail.png";
NSString * const MTDocumentInfoKeyThumbnailRetna = @"thumbnail@2x.png";
NSString * const MTDocumentInfoKeyMeta = @"meta.plist";
NSString * const MTDocumentInfoKeyVersion = @"version";
NSString * const MTDocumentInfoKeyGenerator = @"generator";

NSString * const MTDocumentInfoKeyMetaEditor = @"editor";
NSString * const MTDocumentInfoKeyMetaFileVersion = @"fileversion";
NSString * const MTDocumentInfoKeyMetaDateCreated = @"datacreated";

@interface MADocument ()

@property (nonatomic, retain) NSFileWrapper *fileWrapper;
@property (nonatomic, retain) NSMutableDictionary *extraInformation;        //Structure for extra info
@property (nonatomic, retain) UIImage *thumbnail;

@end

@implementation MADocument

- (void)dealloc {
    [_extraInformation release];
    [_thumbnail release];
    [_fileWrapper release];
    [super dealloc];
}

- (id)initWithFileURL:(NSURL *)url {
    self = [super initWithFileURL:url];
    if (self) {
        
        NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
        [self setExtraInformation:extraInfo];
        [extraInfo release];
                
    }
    return self;
}

/*
 {
    additionalContent =     {
        generator = "MAD Designer";
        "thumbnail.png" = "<UIImage: 0x1fea0b10>";
        version = 1;
    };
    fileType = "com.everydayapps.productivity.mad";
    parentContext = "<NSManagedObjectContext: 0x1f8bf550>";
 }
 */

NSString * MTDocumentAdditionalContentKey       = @"additionalContent";
NSString * MTDocumentFileTypeKey                = @"fileType";
NSString * MTDocumentParentContextKey           = @"parentContext";

NSString * MTDocumentAdditionalContentFileName  = @"sup";
NSString * MTDocumentGeneratorFileName          = @"gen";
NSString * MTDocumentThumbnailFileName          = @"img";
NSString * MTDocumentVersionFileName            = @"ver";
NSString * MTDocumentTypenFileName              = @"typ";
NSString * MTDocumentParentContextName          = @"moc";


- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {
    id result = [super contentsForType:typeName error:outError];
    return result;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    BOOL result = [super loadFromContents:contents ofType:typeName error:outError];
    return result;
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
    MTLog(@"UIManagedDocument error: %@", [error localizedDescription]);
    NSArray *errors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if (errors != nil && errors.count > 0) {
        for (NSError *error in errors) {
            MTLog(@"  Error: %@", error.userInfo);
        }
    } else {
        MTLog(@"  %@", error.userInfo);
    }
}

- (NSString *)name {
    return [[[self fileURL] lastPathComponent] stringByDeletingPathExtension];
}

+ (NSString *)thumbnailSaveName {
    return [UIDevice isRetnaDisplay] ? MTDocumentInfoKeyThumbnailRetna : MTDocumentInfoKeyThumbnailStandard;
}

#pragma mark - UIManagedDocument

- (BOOL)readAdditionalContentFromURL:(NSURL *)absoluteURL error:(NSError **)error {
    
    NSError *readError = nil;
    NSURL *thumbnailUrl = [absoluteURL URLByAppendingPathComponent: [MADocument thumbnailSaveName]];
    NSData *imageData = [NSData dataWithContentsOfURL: thumbnailUrl options:NSDataReadingUncached error:&readError];

    if (imageData != nil && readError == nil) {
        UIImage *image = [UIImage imageWithData: imageData];
        if (image != nil) {
            [[self extraInformation] setObject:[UIImage imageWithData: imageData]
                                        forKey:[MADocument thumbnailSaveName]];
        }
    }
    
    NSURL *metaUrl = [absoluteURL URLByAppendingPathComponent:@"meta.plist"];
    readError = nil;

    NSDictionary *dicionary = [NSDictionary dictionaryWithContentsOfURL:metaUrl];
    
    NSString *lastGenerator = [dicionary objectForKey:MTDocumentInfoKeyGenerator];
    if (lastGenerator == nil) {
        lastGenerator = @"MAD Designer";
    }
    
    [[self extraInformation] setObject:lastGenerator
                                forKey:MTDocumentInfoKeyGenerator];

    NSNumber *lastVersion = [dicionary objectForKey:MTDocumentInfoKeyGenerator];
    if (lastVersion == nil) {
        lastVersion = @(1.0);
    }
    
    [[self extraInformation] setObject:lastVersion
                                forKey:MTDocumentInfoKeyVersion];

    return YES;
}

- (id)additionalContentForURL:(NSURL *)absoluteURL error:(NSError **)error {
    //NSLog(@"AURL %@", absoluteURL);
    
    if ([self extraInformation] == nil) {
        NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
        [self setExtraInformation:extraInfo];
        [extraInfo release];
        
        if ([self thumbnail] == nil) {
            UIImage *thumbnail = [[UIImage imageNamed:@"UIImageDocumentBlank"] retain];
            [[self extraInformation] setObject:thumbnail forKey:[MADocument thumbnailSaveName]];
            [self setThumbnail:thumbnail];
            [thumbnail release];
        }
    }
    
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:[self managedObjectContext]];
    if (document != nil) {
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:document];
        UIImage *thumbnail = [[printPageRender thumbnail] retain];
        [[self extraInformation] setObject:thumbnail forKey:[MADocument thumbnailSaveName]];
        [self setThumbnail:thumbnail];
        [thumbnail release];
        [printPageRender release];
    }
    [[self extraInformation] setObject:@(1.0) forKey:MTDocumentInfoKeyVersion];
    [[self extraInformation] setObject:@"MAD Designer" forKey:MTDocumentInfoKeyGenerator];

    return [self extraInformation];
}

- (BOOL)writeAdditionalContent:(id)content toURL:(NSURL *)absoluteURL originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)error {

    if (content) {

        NSURL *thumbnailUrl = [[absoluteURL URLByAppendingPathComponent:[MADocument thumbnailSaveName]] retain];
        NSError *filePresenterError = nil;
        
        UIImage *thumbnail = [[(NSDictionary *)content objectForKey:[MADocument thumbnailSaveName]] retain];
        [UIImagePNGRepresentation(thumbnail) writeToURL:thumbnailUrl atomically:NO];

        NSURL *metaUrl = [absoluteURL URLByAppendingPathComponent:@"meta.plist"];
        id version = [content objectForKey:MTDocumentInfoKeyVersion];
        id generator = [content objectForKey:MTDocumentInfoKeyGenerator];
        [(NSDictionary *)@{MTDocumentInfoKeyVersion:version, MTDocumentInfoKeyGenerator:generator} writeToURL:metaUrl atomically:NO];
        
        if (filePresenterError != nil) {
            [filePresenterError presentErrorToUser];
        }
        [thumbnail release];
        [thumbnailUrl release];

    }
    return YES;
}

- (void)saveContext {
    NSError *error;
    if ([self managedObjectContext] != nil) {
        if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
            [error presentErrorToUserWithContinue:^(BOOL success) {
                [self saveContext];
            }];
        }
    }
}

- (void)save:(void (^)(BOOL success))completion {
    [self saveToURL: [self fileURL] forSaveOperation: UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        if (completion != nil) {
            completion(success);
        }
  }];
}

- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:[self fileURL] error:&error];
    BOOL success = error == nil;
    if (completion != nil) completion(success);
}

@end
