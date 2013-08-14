#import <UIKit/UIKit.h>
#import "Constants.h"

@interface CloudManager : NSObject 

@property (nonatomic, assign) BOOL isCloudEnabled;
@property (nonatomic, retain, readonly) NSURL *dataDirectoryURL;
@property (nonatomic, retain, readonly) NSURL *documentsDirectoryURL;

+ (CloudManager *)sharedManager;

@end

NSString * const ICloudStateUpdatedNotification;
NSString * const UbiquitousContainerFetchingWillBeginNotification;
NSString * const UbiquitousContainerFetchingDidEndNotification;
