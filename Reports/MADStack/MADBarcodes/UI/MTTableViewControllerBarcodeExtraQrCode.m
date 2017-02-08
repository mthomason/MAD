//
//  MTTableViewControllerBarcodeExtraQrCode.m
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableViewControllerBarcodeExtraQrCode.h"
#import "MTTableViewControllerStaticSelectRow.h"
#import <UIKit/UILabel.h>
#import <UIKit/UIStoryboardSegue.h>

@interface MTTableViewControllerBarcodeExtraQrCode ()
    <MTTableViewControllerStaticSelectRowDelegate>

@property (nonatomic, assign) BOOL displayingSize;
@property (nonatomic, assign) BOOL displayingErrorCorrection;

@end

@implementation MTTableViewControllerBarcodeExtraQrCode

#pragma mark - Exit

- (IBAction)unwindToBarcodeExtraQrCode:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return action == @selector(unwindToBarcodeExtraQrCode:);
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return action == @selector(unwindToBarcodeExtraQrCode:) ?
            self :
            [super viewControllerForUnwindSegueAction: action
                                   fromViewController: fromViewController
                                           withSender: sender];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setDisplayingSize:NO];
    [self setDisplayingErrorCorrection:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateCells];
}

- (void)updateCells {
    BOOL autoresize = [self.delegate barcodeQrCodeAutomaticResizing];
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
        NSInteger initalErrorCorrecion = [self.delegate barcodeQrCodeInitalErrorCorrection];
        if (initalErrorCorrecion == 0) {
            cellError.detailTextLabel.text = automatic;
            cellSize.detailTextLabel.text = @"Custom";
        }
        NSInteger initalSize = [self.delegate barcodeQrCodeInitalSize];
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
    if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasQrCodeError"] ||
        [segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasQrCodeSize"]) {
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
                    [self.delegate barcodeQrCodeDidEnableAutomaticResizing];
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
    id <MTTableViewControllerBarcodeExtraQrCodeDelegate> delegate;
    delegate = self.delegate;
    return self.displayingSize ? [delegate barcodeQrCodeInitalSize] :
                                 [delegate barcodeQrCodeInitalErrorCorrection];
}

- (void)didSelectTag:(NSInteger)tag {
    id <MTTableViewControllerBarcodeExtraQrCodeDelegate> delegate;
    delegate = self.delegate;
    if (self.displayingSize) {
        [delegate barcodeQrCodeDidSetSize:tag];
    } else {
        [delegate barcodeQrCodeDidSetErrorCorrection:tag];
    }
    [self updateCells];
}

@end
