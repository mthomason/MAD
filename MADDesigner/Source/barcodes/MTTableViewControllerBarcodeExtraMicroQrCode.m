//
//  MTTableViewControllerBarcodeExtraMicroQrCode.m
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableViewControllerBarcodeExtraMicroQrCode.h"
#import "MTTableViewControllerStaticSelectRow.h"
#import <UIKit/UILabel.h>
#import <UIKit/UIStoryboardSegue.h>

@interface MTTableViewControllerBarcodeExtraMicroQrCode ()
    <MTTableViewControllerStaticSelectRowDelegate>

    @property (nonatomic, assign) BOOL displayingSize;
    @property (nonatomic, assign) BOOL displayingErrorCorrection;

@end

@implementation MTTableViewControllerBarcodeExtraMicroQrCode

#pragma mark - Exit

- (IBAction)unwindToBarcodeExtraMicroQrCode:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController sender:(id)sender {
	if (action == @selector(unwindToBarcodeExtraMicroQrCode:)) {
		return YES;
	}
	return [super canPerformUnwindSegueAction:action fromViewController:fromViewController sender:sender];
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) { }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setDisplayingSize:NO];
    [self setDisplayingErrorCorrection:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateCells];
}

- (void)updateCells {
    id <MTTableViewControllerBarcodeExtraMicroQrCodeDelegate> delegate;
    delegate = self.delegate;
    BOOL autoresize = [delegate barcodeMicroQrCodeAutomaticResizing];
    UITableViewCell *cellSize = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell *cellError = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    UITableViewCell *cellAuto = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    NSString *automatic = NSLocalizedString(@"Automatic", @"Automatic");
    if (autoresize) {
        cellAuto.accessoryType = UITableViewCellAccessoryCheckmark;
        cellSize.detailTextLabel.text = automatic;
        cellError.detailTextLabel.text = automatic;
    } else {
        cellAuto.accessoryType = UITableViewCellAccessoryNone;
        NSInteger initalErrorCorrecion = [delegate barcodeMicroQrCodeInitalErrorCorrection];
        if (initalErrorCorrecion == 0) {
            cellError.detailTextLabel.text = automatic;
            cellSize.detailTextLabel.text = @"Custom";
        }
        NSInteger initalSize = [delegate barcodeMicroQrCodeInitalSize];
        if (initalSize == 0) {
            cellSize.detailTextLabel.text = automatic;
            cellError.detailTextLabel.text = @"Custom";
        }
    }
    [cellSize setNeedsLayout];
    [cellError setNeedsLayout];
    [cellSize setNeedsDisplay];
    [cellError setNeedsDisplay];
    [cellAuto setNeedsDisplay];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasMicroQrCodeError"] ||
        [segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasMicroQrCodeSize"]) {
        ((MTTableViewControllerStaticSelectRow *)segue.destinationViewController).delegate = self;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    switch (section) {
        case 0:
            
            switch (row) {
                case 0:
                    
                    [self.delegate barcodeMicroQrCodeDidEnableAutomaticResizing];
                    break;
                    
                case 1:
                    [self setDisplayingSize:YES];
                    [self setDisplayingErrorCorrection:NO];
                    break;
                case 2:
                    [self setDisplayingSize:NO];
                    [self setDisplayingErrorCorrection:YES];
                    break;
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    [self updateCells];
}

- (NSInteger)initalRow {
    id <MTTableViewControllerBarcodeExtraMicroQrCodeDelegate> delegate;
    delegate = self.delegate;
    return self.displayingSize ? [delegate barcodeMicroQrCodeInitalSize] :
                                 [delegate barcodeMicroQrCodeInitalErrorCorrection];
}

- (void)didSelectTag:(NSInteger)tag {
    id <MTTableViewControllerBarcodeExtraMicroQrCodeDelegate> delegate;
    delegate = self.delegate;
    if (self.displayingSize) {
        [delegate barcodeMicroQrCodeDidSetSize:tag];
    } else {
        [delegate barcodeMicroQrCodeDidSetErrorCorrection:tag];
    }
    [self updateCells];
}

@end
