#import "CloudManager.h"

NSString *const ICloudStateUpdatedNotification                      = @"ICloudStateUpdatedNotification";
NSString *const UbiquitousContainerFetchingWillBeginNotification    = @"UbiquitousContainerFetchingWillBeginNotification";
NSString *const UbiquitousContainerFetchingDidEndNotification       = @"UbiquitousContainerFetchingDidEndNotification";

static CloudManager *__sharedManager;

@implementation CloudManager
{
    BOOL _isCloudEnabled;
    NSURL* _dataDirectoryURL;
}

@synthesize isCloudEnabled = _isCloudEnabled;
@synthesize dataDirectoryURL = _dataDirectoryURL;

+ (CloudManager*)sharedManager {
    if (!__sharedManager) {
        __sharedManager = [[CloudManager alloc] init];
    }
    return __sharedManager;
}

- (id)init {
    if ((self = [super init])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateICloudEnabled:) name:NSUbiquityIdentityDidChangeNotification object:nil];
        [self updateFileStorageContainerURL:nil];
    }
    
    return self;
}

- (void)setIsCloudEnabled:(BOOL)isCloudEnabled {

    // Asynchronously update our data directory URL and documents directory URL
    // If we're enabling cloud storage, we move any local documents into the cloud container after the URLs are updated.
    
    if (isCloudEnabled != _isCloudEnabled) {
        _isCloudEnabled = isCloudEnabled;
        NSURL* oldDataDirectoryURL = [self dataDirectoryURL];
        NSURL* oldDocumentsDirectoryURL = [self documentsDirectoryURL];
        
        [self updateFileStorageContainerURL:^(void) {
            if (isCloudEnabled) {
                // Now move any existing local documents into iCloud.
                
                NSArray* localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:oldDocumentsDirectoryURL includingPropertiesForKeys:nil options:0 error:nil];
                NSArray* localPreviews = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:oldDataDirectoryURL includingPropertiesForKeys:nil options:0 error:nil];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                    NSFileManager* fileManager = [[NSFileManager alloc] init];
                    NSURL* newDataDirectoryURL = [self dataDirectoryURL];
                    NSURL* newDocumentsDirectoryURL = [self documentsDirectoryURL];
                    
                    for (NSURL* documentURL in localDocuments) {
                        if ([[documentURL pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocument]) {
                            NSURL* destinationURL = [newDocumentsDirectoryURL URLByAppendingPathComponent:[documentURL lastPathComponent]];
                            [fileManager setUbiquitous:YES itemAtURL:documentURL destinationURL:destinationURL error:nil];
                        }
                    }
                    
                    for (NSURL* previewURL in localPreviews) {
                        if ([[previewURL pathExtension] isEqualToString:@"preview"]) {
                            NSURL* destinationURL = [newDataDirectoryURL URLByAppendingPathComponent:[previewURL lastPathComponent]];
                            [fileManager setUbiquitous:YES itemAtURL:previewURL destinationURL:destinationURL error:nil];
                        }
                    }
                });
            }
        }];
        [[NSNotificationCenter defaultCenter] postNotificationName:ICloudStateUpdatedNotification object:nil];
    }
}

- (NSURL*)documentsDirectoryURL {
    return [_dataDirectoryURL URLByAppendingPathComponent:@"Documents"];
}

- (void)updateFileStorageContainerURL:(void (^)(void))completionHandler {

    @synchronized (self) {
        _dataDirectoryURL = nil;
        if (self.isCloudEnabled) {
            [[NSNotificationCenter defaultCenter] postNotificationName:UbiquitousContainerFetchingWillBeginNotification object:nil];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                _dataDirectoryURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:MTDocumentTypeUtiMad];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:UbiquitousContainerFetchingDidEndNotification object:nil];
                    
                    if (completionHandler) {
                        completionHandler();
                    }
                });
            });
        } else {
            _dataDirectoryURL = [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
        }
    }
}

- (void)updateICloudEnabled:(NSNotification*)notification {
    
    if ([[NSFileManager defaultManager] ubiquityIdentityToken]) {
        if ([self isCloudEnabled]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ICloudStateUpdatedNotification object:nil];
        }
    }
    else {
        [self setIsCloudEnabled: NO];
    }
}

@end
