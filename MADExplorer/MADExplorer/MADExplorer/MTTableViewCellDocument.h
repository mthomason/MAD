//
//  UITableViewCellDocument.h
//  Reports
//
//  Created by Michael Thomason on 1/7/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTTableViewCellDocument_h
#define Reports_MTTableViewCellDocument_h

#import <UIKit/UIKit.h>
#import "MTDocumentCellProtocol.h"

@interface MTTableViewCellDocument : UITableViewCell

    @property (nonatomic, weak) IBOutlet UILabel *labelH1;
    @property (nonatomic, weak) IBOutlet UIImageView *imageThumbnail;
    @property (nonatomic, weak) id <MTDocumentCellProtocol> delegate;

@end

#endif
