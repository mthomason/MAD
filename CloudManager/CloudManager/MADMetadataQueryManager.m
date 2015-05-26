//
//  MADFileLocationManager.m
//  MAD
//
//  Created by Michael Thomason on 9/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADMetadataQueryManager.h"
#import "MADMetaData.h"

NSString * const MADKeyDisplayNameShort                 = @"d";
NSString * const MADKeyPathShort                        = @"p";
NSString * const MADKeyMetadataShort                    = @"m";

NSString * const MADUtiType                             = @"com.everydayapps.productivity.mad";
NSString * const MADUtiPublicData                       = @"public.data";
NSString * const MADPredicateFormatDocument             = @"%K.pathExtension == %@ && %K == %@";

//NSString * const MADNotificationCloudActivityStarted    = @"MADNotificationCloudActivityStarted";
//NSString * const MADNotificationCloudActivityCompleted  = @"MADNotificationCloudActivityCompleted";

@interface MADMetadataQueryManager ()

@property (nonatomic, strong, readwrite) NSMetadataQuery *metadataQuery;
@property (nonatomic, strong, readwrite) NSURL *documentsDirectory;

@property (nonatomic, strong, readwrite) NSMutableDictionary *results;

@property (nonatomic, strong, readwrite) NSArray *metadata;

@end

@implementation MADMetadataQueryManager

#pragma mark - Static Functions

+ (NSString *)keyResults {
    return NSStringFromSelector(@selector(results));
}

#pragma mark - NSObject


@end
