#import <UIKit/UIKit.h>
#import "Constants.h"

@interface CloudManager : NSObject 

@property (nonatomic) BOOL isCloudEnabled;
@property (nonatomic, readonly) NSURL* dataDirectoryURL;
@property (nonatomic, readonly) NSURL* documentsDirectoryURL;

+ (CloudManager*)sharedManager;

@end

NSString * const ICloudStateUpdatedNotification;
NSString * const UbiquitousContainerFetchingWillBeginNotification;
NSString * const UbiquitousContainerFetchingDidEndNotification;
