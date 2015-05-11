//
//  MTDocumentObjectNewAggregateViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTGroupByViewController.h"
#import "MTQueryBuilderChooseFieldViewController.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDocumentObjectAggregate.h"
#import "RptqDocumentObjectAggregate+Extras.h"

#import "MTAggregateFunctionsViewController.h"
#import "MADNavigationBarTitleView.h"

NSString * const MTSegueAggregateFunctionCount      = @"MTSegueAggregateFunctionCount";
NSString * const MTSegueAggregateFunctionFirst      = @"MTSegueAggregateFunctionFirst";
NSString * const MTSegueAggregateFunctionLast       = @"MTSegueAggregateFunctionLast";
NSString * const MTSegueAggregateFunctionMaximum    = @"MTSegueAggregateFunctionMaximum";
NSString * const MTSegueAggregateFunctionMean       = @"MTSegueAggregateFunctionMean";
NSString * const MTSegueAggregateFunctionMinimum    = @"MTSegueAggregateFunctionMinimum";
NSString * const MTSegueAggregateFunctionSum        = @"MTSegueAggregateFunctionSum";
NSString * const MTSegueAggregateGroupTypeSave      = @"MTSegueAggregateGroupTypeSave";
NSString * const MTSegueAggregateFieldSave          = @"MTSegueAggregateFieldSave";
NSString * const MADSegueAggregateFunctionField     = @"MADSegueAggregateFunctionField";
NSString * const MTIdentifierSegueDocumentObjectEditAggregate = @"MTIdentifierSegueDocumentObjectEditAggregate";
NSString * const MTDocumentObjectNewAggregateViewControllerIdentifier = @"MTDocumentObjectNewAggregateViewControllerIdentifier";
NSString * const MTDocumentObjectNewAggregateNavigationControllerIdentifier = @"MTDocumentObjectNewAggregateNavigationControllerIdentifier";

@interface MTDocumentObjectNewAggregateViewController ()
    <MTAggregateFunctionsViewControllerDelegate,
        MTGroupByViewControllerDelegate,
        MTQueryBuilderChooseFieldDelegate>

@property(nonatomic, strong) RptqDocumentObjectAggregate *aggregateDocumentObject;

@end

@implementation MTDocumentObjectNewAggregateViewController

@synthesize unwindViewController;

#pragma mark - MTQueryBuilderChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish: (MTQueryBuilderChooseFieldViewController *)controller
                                      withField: (RptqQueryField *)field {
    [self setFieldObject:field];
    [self setFieldObjectId: [field objectID]];
    
    NSString *formatString = NSLocalizedString(@"Field: %@", @"Field: %@");
    NSString *detail = [NSString stringWithFormat:formatString, [field display]];
    self.tableViewCellAggregateInput.detailTextLabel.text = detail;
    [self updateDisplay];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - MTGroupByViewControllerDelegate

- (void)didSelectGroupByPage {
    NSString *detail = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypePage];
    self.groupTypeSectionNumber = 0;
    self.aggregateGroupByType = MTAggregateGroupByTypePage;
    self.tableViewCellAggregateGroupBy.detailTextLabel.text = detail;

    [self updateDisplay];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didSelectGroupByReport {
    NSString *detail = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeReport];
    self.groupTypeSectionNumber = 0;
    self.aggregateGroupByType = MTAggregateGroupByTypeReport;
    self.tableViewCellAggregateGroupBy.detailTextLabel.text = detail;

    [self updateDisplay];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didSelectGroupBySectionNumber:(NSUInteger)groupNumber {
    NSString *format = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeSection];
    NSString *detail = [NSString stringWithFormat:format, groupNumber];
    self.groupTypeSectionNumber = groupNumber;
    self.aggregateGroupByType = MTAggregateGroupByTypeSection;
    self.tableViewCellAggregateGroupBy.detailTextLabel.text = detail;

    [self updateDisplay];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - MTAggregateFunctionsViewControllerDelegate

- (void)didSelectFunction:(MTAggregateFunctionType)aggregateFunctionType {
    if (aggregateFunctionType != MTAggregateFunctionTypeNotSet) {
        self.aggregateFunctionType = aggregateFunctionType;
        NSString *functionName = [RptqDocumentObjectAggregate displayStringForType:aggregateFunctionType];
        NSString *detailText = [NSString stringWithFormat:@"%@()", functionName];
        self.tableViewCellAggrageFunction.detailTextLabel.text = detailText;
    }
    
    [self updateDisplay];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Exit

- (IBAction)unwindToNewAggregateFunction:(UIStoryboardSegue *)action {
    
    MTAggregateFunctionType aggregateFunctionType = MTAggregateFunctionTypeNotSet;
    
    if ([[action identifier] isEqualToString:MTSegueAggregateFunctionCount]) {
        
        aggregateFunctionType = MTAggregateFunctionTypeCount;
        
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFunctionFirst]) {
        
        aggregateFunctionType = MTAggregateFunctionTypeFirst;
        
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFunctionLast]) {
        
        aggregateFunctionType = MTAggregateFunctionTypeLast;
        
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFunctionMaximum]) {
        
        aggregateFunctionType = MTAggregateFunctionTypeMax;
        
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFunctionMean]) {
        
        aggregateFunctionType = MTAggregateFunctionTypeMean;
        
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFunctionMinimum]) {
        
        aggregateFunctionType = MTAggregateFunctionTypeMin;
        
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFunctionSum]) {
        
        aggregateFunctionType = MTAggregateFunctionTypeSum;
        
    } else if ([[action identifier] isEqualToString:MTSegueAggregateGroupTypeSave]) {
        
        MTGroupByViewController *groupByViewController = [action sourceViewController];
        self.aggregateGroupByType = groupByViewController.aggregateGroupType;
        self.groupTypeSectionNumber = groupByViewController.aggregateGroupNumber;
        
        switch ([self aggregateGroupByType]) {
            case MTAggregateGroupByTypeSection: {
                
                NSUInteger group = [self groupTypeSectionNumber];
                NSString *format = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeSection];
                NSString *detail = [NSString stringWithFormat:format, group];
                [[[self tableViewCellAggregateGroupBy] detailTextLabel] setText:detail];
                break;
                
            }
            case MTAggregateGroupByTypeReport: {
                
                NSString *detailText = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeReport];
                [[[self tableViewCellAggregateGroupBy] detailTextLabel] setText:detailText];
                break;
                
            }
            case MTAggregateGroupByTypePage: {
                
                NSString *detailText = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypePage];
                [[[self tableViewCellAggregateGroupBy] detailTextLabel] setText:detailText];
                break;
                
            }
            default:
                [[[self tableViewCellAggregateGroupBy] detailTextLabel] setText:@""];
                break;
        }
        
        
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFieldSave]) {
        
        MTQueryBuilderChooseFieldViewController *dynamicFieldController = [action sourceViewController];
        RptqQueryField *queryField = [dynamicFieldController queryField];
        [self setFieldObject:queryField];
        [self setFieldObjectId: [queryField objectID]];
        
        NSString *formatString = NSLocalizedString(@"Field: %@", @"Field: %@");
        NSString *detailtext = [NSString stringWithFormat:formatString, [queryField display]];
        [[[self tableViewCellAggregateInput] detailTextLabel] setText:detailtext];
        
    }
    
    if (aggregateFunctionType != MTAggregateFunctionTypeNotSet) {
        [self setAggregateFunctionType:aggregateFunctionType];
        NSString *functionName = [RptqDocumentObjectAggregate displayStringForType:aggregateFunctionType];
        NSString *detailText = [NSString stringWithFormat:@"%@()", functionName];
        [[[self tableViewCellAggrageFunction] detailTextLabel] setText:detailText];
    }
    
    [self updateDisplay];
}
/*
- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return self.delegate == nil;
}
*/
/*- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return self.unwindViewController ?
            self.unwindViewController :
            [super viewControllerForUnwindSegueAction: action
                           fromViewController: fromViewController
                                   withSender: sender];
}*/

- (void)updateDisplay {
    
    [self updateField];
    [self updateFunctionType];
    [self updateGroupType];
    
    if (self.delegate) {

        NSNumber *groupNumber = @([self groupTypeSectionNumber]);
        [self.delegate didUpdateggregateFunctionWithType:[self aggregateFunctionType]
                                                 inputType:MTAggregateFunctionInputTypeField
                                               inputObject:[self fieldObject]
                                                 groupType:[self aggregateGroupByType]
                                               groupNumber:groupNumber];
    }
    self.navigationItem.rightBarButtonItem.enabled = [self fieldObject] != nil;
}

- (void)updateField {
    NSString *formatString = NSLocalizedString(@"Field: %@", @"Field: %@");
    NSString *detailtext = [NSString stringWithFormat:formatString, [[self fieldObject] display]];
    self.tableViewCellAggregateInput.detailTextLabel.text = detailtext;
}

- (void)updateFunctionType {
    NSString *functionName = [RptqDocumentObjectAggregate displayStringForType:[self aggregateFunctionType]];
    NSString *detailText = [NSString stringWithFormat:@"%@(x)", functionName];
    self.tableViewCellAggrageFunction.detailTextLabel.text = detailText;
}

- (void)updateGroupType {
    switch ([self aggregateGroupByType]) {
        case MTAggregateGroupByTypeSection: {
            
            NSUInteger group = [self groupTypeSectionNumber];
            NSString *format = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeSection];
            NSString *detail = [NSString stringWithFormat:format, group];
            self.tableViewCellAggregateGroupBy.detailTextLabel.text = detail;
            break;
            
        }
        case MTAggregateGroupByTypeReport: {
            
            NSString *detailText = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeReport];
            self.tableViewCellAggregateGroupBy.detailTextLabel.text = detailText;
            break;
            
        }
        case MTAggregateGroupByTypePage: {
            
            NSString *detailText = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypePage];
            self.tableViewCellAggregateGroupBy.detailTextLabel.text = detailText;
            break;
            
        }
        default:
            self.tableViewCellAggregateGroupBy.detailTextLabel.text = @"";
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"MTSegueNewDocumentObjectAggregateLabelSaveIdentifer"]) {

    } else if ([segue.identifier isEqualToString:@"MTSegueAggregateFunctionChooser"]) {
    
        ((MTAggregateFunctionsViewController *)segue.destinationViewController).delegate = self;
        ((MTAggregateFunctionsViewController *)segue.destinationViewController).selectedFunctionType = self.aggregateFunctionType;

    } else if ([segue.identifier isEqualToString:@"MTSegueGroupByPush"]) {

        ((MTGroupByViewController *)segue.destinationViewController).delegate = self;
        ((MTGroupByViewController *)segue.destinationViewController).document = self.document;
        [((MTGroupByViewController *)segue.destinationViewController) selectGroupType: self.aggregateGroupByType
                                                                    withSectionNumber: self.groupTypeSectionNumber];
        
    } else if ([segue.identifier isEqualToString:@"MADSegueAggregateFunctionField"]) {
        ((MTQueryBuilderChooseFieldViewController *)segue.destinationViewController).document = self.document;
        ((MTQueryBuilderChooseFieldViewController *)segue.destinationViewController).delegate = self;
    }

}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setEditmode:NO];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setAggregateObjectToEdit:(RptqDocumentObjectAggregate *)aggregateDocumentObject {
    self.aggregateFunctionType = aggregateDocumentObject.function.integerValue;
    self.aggregateGroupByType = aggregateDocumentObject.groupType.integerValue;
    self.groupTypeSectionNumber = aggregateDocumentObject.groupNumber.integerValue;
    self.fieldObjectId = aggregateDocumentObject.aggregateField.objectID;
    self.fieldObject = aggregateDocumentObject.aggregateField;
    self.editmode = YES;

    [self setAggregateDocumentObject:aggregateDocumentObject];

}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.hidesBackButton = NO;
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame:CGRectZero];
    titleView.text = NSLocalizedString(@"Aggregate Function", @"Title of form to create a non changing text label document object.");
    self.navigationItem.titleView = titleView;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self editmode]) {
        [self setEditmode:NO];
    }
    [self updateDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
