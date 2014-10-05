//
//  MTTableViewControllerBarcodeExtraGridMatrix.m
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableViewControllerBarcodeExtraPdf417Iso24728.h"
#import "MTTableViewControllerStaticSelectRow.h"

#ifndef NS_DESIGNATED_INITIALIZER
#if __has_attribute(objc_designated_initializer)
#define NS_DESIGNATED_INITIALIZER __attribute((objc_designated_initializer))
#else
#define NS_DESIGNATED_INITIALIZER
#endif
#endif

@interface MTTableViewControllerBarcodeExtraPdf417Iso24728 ()
    <MTTableViewControllerStaticSelectRowDelegate>

@property (nonatomic, assign) BOOL displayingWidth;
@property (nonatomic, assign) BOOL displayingFormat;
@property (nonatomic, assign) BOOL displayingErrorCorrection;

@end

@implementation MTTableViewControllerBarcodeExtraPdf417Iso24728

#pragma mark - Exit

- (IBAction)unwindToBarcodeExtraGridMatrix:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return action == @selector(unwindToBarcodeExtraGridMatrix:);
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return action == @selector(unwindToBarcodeExtraGridMatrix:) ?
            self :
            [super viewControllerForUnwindSegueAction: action
                                   fromViewController: fromViewController
                                           withSender: sender];
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) { }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.displayingWidth = NO;
    self.displayingErrorCorrection = NO;
    self.displayingFormat = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateCells];
}

- (void)updateCells {
    
    NSIndexPath *pathSize = [NSIndexPath indexPathForRow:0 inSection:0];
    NSIndexPath *pathError = [NSIndexPath indexPathForRow:1 inSection:0];
    NSIndexPath *pathFormat = [NSIndexPath indexPathForRow:2 inSection:0];

    UITableViewCell *cellSize = [self.tableView cellForRowAtIndexPath:pathSize];
    UITableViewCell *cellError = [self.tableView cellForRowAtIndexPath:pathError];
    UITableViewCell *cellFormat = [self.tableView cellForRowAtIndexPath:pathFormat];

    NSString *localziedSize, *localizedError, *localizedFormat;
    
    NSInteger width = [self.delegate barcodePDF417Columns];
    NSInteger errorCorrection = [self.delegate barcodePDF417ErrorCorrection];
    NSInteger format = [self.delegate barcodePDF417Format];
    
    if (width == 0) {
        
        localziedSize = NSLocalizedString(@"Automatic", @"Automatic");
        
    } else if (width > 0 && width <= 30) {
        
        localziedSize = [NSString stringWithFormat:@"%ld", (long)width];
        
    } else {
        width = 1;
        localziedSize = @"1";
    }
    
    if (errorCorrection == 0) {
        localizedError = NSLocalizedString(@"Automatic", @"Automatic");
    } else if (errorCorrection > 1 && errorCorrection <= 9) {
        errorCorrection = errorCorrection - 1;
        localizedError = [NSString stringWithFormat:@"%ld", (long)errorCorrection];
    } else {
        errorCorrection = 0;
        localizedError = NSLocalizedString(@"Automatic", @"Automatic");
    }
    
    switch (format) {
        case 0:
            localizedFormat = @"";
            break;
        case 1:
            localizedFormat = @"";
            break;
        case 2:
            localizedFormat = @"";
            break;
        default:
            break;
    }
    
    cellSize.detailTextLabel.text = @"";
    cellError.detailTextLabel.text = @"";
    cellFormat.detailTextLabel.text = @"";
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasPdf417Columns"] ||
        [segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasPdf417ErrorCorrectionCapacity"] ||
        [segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasPdf417Format"]) {
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
                    self.displayingWidth = YES;
                    self.displayingErrorCorrection = NO;
                    self.displayingFormat = NO;
                    break;
                    
                case 1:
                    self.displayingWidth = NO;
                    self.displayingErrorCorrection = YES;
                    self.displayingFormat = NO;
                    break;
                    
                case 2:
                    self.displayingWidth = NO;
                    self.displayingErrorCorrection = NO;
                    self.displayingFormat = YES;
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
    return 0;
    // [self displayingSize] ? [self.delegate barcodeGridMatrixInitalSize] : [self.delegate barcodeGridMatrixInitalErrorCorrection];
}

- (void)didSelectTag:(NSInteger)tag {
    
    if (self.displayingWidth) {
        
        [self.delegate barcodePDF417DidSetColumns:tag];
        
    } else if (self.displayingErrorCorrection) {
        
        [self.delegate barcodePDF417DidSetErrorCorrection:tag];
        
    } else if (self.displayingFormat) {
        
        [self.delegate barcodePDF417DidSetFormat:tag];
        
    }
    
    [self updateCells];
}

@end
