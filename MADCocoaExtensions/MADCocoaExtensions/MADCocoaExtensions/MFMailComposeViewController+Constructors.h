//
//  MFMailComposeViewController+Constructors.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADExtensions_MFMailComposeViewController_Constructors_h
#define MADExtensions_MFMailComposeViewController_Constructors_h

#import <MessageUI/MessageUI.h>

@interface MFMailComposeViewController (Constructors)

+ (instancetype)title:(NSString *)title
                 body:(NSString *)body
   userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom;

+ (instancetype)body:(NSString *)body
          attachment:(NSURL *)attachmentURL
            mimeType:(NSString *)mimeType
  userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom;

@end

#endif
