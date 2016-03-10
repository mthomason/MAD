//
//  MADConstants.m
//  MAD
//
//  Created by Michael Thomason on 4/2/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADConstants.h"

NSString * const MADFileExtentionMobleApplicationDocument           = @"mad";
NSString * const MADFileExtentionMobleApplicationDocumentArchive    = @"mada";
NSString * const MADTrademark                                       = @"MAD";
NSString * const MADIdentifierGroup                                 = @"group.everydayapps.mad";

#if MAD_DESIGNER || MADWATCHKIT
NSString * const MADUbiquityIdentifier                                  = @"iCloud.com.everydayapps.mad.designer";
#elif MAD_VIEWER
NSString * const MADUbiquityIdentifier                                  = @"iCloud.com.everydayapps.mad.viewer";
#endif
