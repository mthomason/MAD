//
//  MADTableViewCellReceiptApplication.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/22/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADTableViewCellReceiptApplication_h
#define MAD_Designer_MADTableViewCellReceiptApplication_h

#import <UIKit/UITableViewCell.h>

@interface MADTableViewCellReceiptApplication : UITableViewCell

    @property (weak, nonatomic) IBOutlet UILabel *product;
    @property (weak, nonatomic) IBOutlet UILabel *version;

@end

#endif
