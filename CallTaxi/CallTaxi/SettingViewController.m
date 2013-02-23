//
//  SettingViewController.m
//  CallTaxi
//
//  Created by Fan Lv on 13-2-7.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import <MessageUI/MFMailComposeViewController.h>
#import "SettingViewController.h"
#import "SVWebViewController.h"
#import "OperateAgreement.h"
#import "SGInfoAlert.h"
#import "Common.h"

@interface SettingViewController ()<MFMailComposeViewControllerDelegate>

@property (strong,nonatomic) UIAlertView *phoneNumberAlertView;
@property (strong,nonatomic) UIAlertView *referrerAlertView;


@end

@implementation SettingViewController

@synthesize phoneNumberAlertView = _phoneNumberAlertView;
@synthesize referrerAlertView = _referrerAlertView;

//------------const tag
const int phoneNumberAlertViewTag =100;
const int phoneNumberAlertViewTextFieldTag =101;

const int referrerAlertViewTag =102;
const int referrerAlertViewTextFieldTag =103;

- (UIAlertView *)referrerAlertView
{
    if (_referrerAlertView == nil)
    {
        _referrerAlertView = [[UIAlertView alloc] initWithTitle:@"请输推荐人姓名" message:nil delegate:self
                                              cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        _referrerAlertView.tag = referrerAlertViewTag;
        _referrerAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;

        UITextField *textField = [_referrerAlertView textFieldAtIndex:0];
        textField.text = [OperateAgreement Referrer];
        textField.tag = referrerAlertViewTextFieldTag;
        [_referrerAlertView addSubview:textField];
    }
    return  _referrerAlertView;
}

- (UIAlertView *)phoneNumberAlertView
{
    if (_phoneNumberAlertView == nil)
    {
        _phoneNumberAlertView = [[UIAlertView alloc] initWithTitle:@"请输入本机号码" message:nil delegate:self
                                                 cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        _phoneNumberAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        _phoneNumberAlertView.tag = phoneNumberAlertViewTag;
        UITextField *textField = [_phoneNumberAlertView textFieldAtIndex:0];
        textField.text = [OperateAgreement UserPhoneNumber];
        textField.tag = phoneNumberAlertViewTextFieldTag;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        [_phoneNumberAlertView addSubview:textField];
    }
    return  _phoneNumberAlertView;
}

#pragma mark - View LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 3;
    }
    return 5;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0)
        {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"当前城市：%@",[OperateAgreement ServerCityName]];
        }
        if (indexPath.row == 1)
        {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"搜索范围（公里）：%d",[OperateAgreement Range]];
        }
        if (indexPath.row == 2)
        {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",[OperateAgreement UserPhoneNumber]];
        }
    }
    if (indexPath.section == 1)
    {
        if (indexPath.row == 0)
        {
            NSString *peopleName = [OperateAgreement Referrer];
            if (peopleName.length == 0)
                peopleName = @"空";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",peopleName];
        }

    }
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 2)
    {
        [self.phoneNumberAlertView show];
    }

    if (indexPath.section == 1)
    {
        if (indexPath.row == 0)
        {
            UITextField *textField = (UITextField *)[self.referrerAlertView viewWithTag:referrerAlertViewTextFieldTag];
            textField.text = [OperateAgreement Referrer];
            [self.referrerAlertView show];
        }
        if (indexPath.row == 1)
        {
            MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
            
            if (mc != nil)
            {
                mc.mailComposeDelegate = self;
                NSString *emailAddress = @"fanlvlgh@gmail.com";
                [mc setToRecipients:[NSArray arrayWithObject:emailAddress]];
                [mc setSubject:@"电召的士 意见反馈"];
                //[self.navigationController pushViewController:mc animated:YES];

                [self presentModalViewController:mc animated:YES];
            }
        }
        if (indexPath.row == 2)
        {
            NSURL *URL = [NSURL URLWithString:COMPANY_WEBSITE];
            SVWebViewController *webViewController = [[SVWebViewController alloc] initWithURL:URL];
            [self.navigationController pushViewController:webViewController animated:YES];
        }
        if (indexPath.row == 3)
        {
            [Common makeCall:[OperateAgreement ServerPhoneNumber]];
        }

    }


    NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:selectedRowIndex animated:YES];

}


#pragma mark  AlertView delegate



- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == phoneNumberAlertViewTag && buttonIndex == 0)
    {
        // ok button
        UITextField *textField = (UITextField *)[actionSheet viewWithTag:phoneNumberAlertViewTextFieldTag];
        NSString *phoneNumber = textField.text;
        NSLog(@"%@",phoneNumber);
        if ([Common isMobileNumber:phoneNumber])
        {
            [OperateAgreement SetUserPhoneNumber:textField.text];
            [self.tableView reloadData];
        }
        else
        {
            [SGInfoAlert showInfo:@"手机号码格式有误，请重新输入。"
                          bgColor:[[UIColor darkGrayColor] CGColor]
                           inView:self.view
                         vertical:0.5];
            self.phoneNumberAlertView = nil;
            [self.phoneNumberAlertView show];
        }
    }
    
    if (actionSheet.tag == referrerAlertViewTag && buttonIndex == 0)
    {
        // ok button
        UITextField *textField = (UITextField *)[actionSheet viewWithTag:referrerAlertViewTextFieldTag];
        NSString *peopleName = textField.text;
        
        [OperateAgreement SetReferrer:peopleName];
        [self.tableView reloadData];

    }
    
    
}

#pragma mark - Mail delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail send canceled...");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved...");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent...");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail send errored: %@...", [error localizedDescription]);
            break;
        default:
            break;
    }
    [self dismissModalViewControllerAnimated:YES];
}

@end
