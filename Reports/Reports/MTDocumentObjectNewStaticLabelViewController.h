//
//  MTDocumentObjectNewStaticLabelViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const MTDocumentObjectNewStaticLabelViewControllerIdentifier;

@interface MTDocumentObjectNewStaticLabelViewController : UITableViewController
    <UITableViewDelegate>

- (NSString *)userInputedText;

@end
