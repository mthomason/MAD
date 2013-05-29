//
//  UITableViewCellDocument.h
//  Reports
//
//  Created by Michael Thomason on 1/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTDocumentCellProtocol.h"

@interface MTDocumentTableViewCell : UITableViewCell

@property (nonatomic, assign) IBOutlet UILabel *labelH1;
@property (nonatomic, assign) IBOutlet UILabel *labelH2;
@property (nonatomic, assign) IBOutlet UIImageView *imageThumbnail;

+ (CGFloat)defaultHeight;
+ (UIImage *)defaultThumbnail;

@property (nonatomic, assign) id <MTDocumentCellProtocol> delegate;

@end
