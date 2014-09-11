//
//  MADOpenFileViewController.h
//  Reports
//
//  Created by Michael Thomason on 9/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFileManager_h
#define Reports_MADFileManager_h

#import <UIKit/UIKit.h>

@interface MADFileManager : NSObject
    <NSCoding>

    @property (nonatomic, strong) NSMutableDictionary *openFiles;   //MADocument stored by their NSURLS
    @property (nonatomic, strong) NSURL *openUrl;

@end

#endif
