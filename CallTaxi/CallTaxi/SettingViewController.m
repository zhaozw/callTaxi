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
#import "AsyncUdpSocket.h"
#import "OperateAgreement.h"
#import "SGInfoAlert.h"
#import "Common.h"

@interface SettingViewController ()<MFMailComposeViewControllerDelegate,UIPickerViewDelegate,UIPickerViewDataSource>


@property (strong,nonatomic) UIAlertView *phoneNumberAlertView;
@property (strong,nonatomic) UIAlertView *referrerAlertView;
@property (strong,nonatomic) NSArray *pickerData;
@property (strong,nonatomic) AsyncUdpSocket *socket;
@property (strong,nonatomic) UIActionSheet *serverCitySelectActionSheet;

@property (weak, nonatomic) IBOutlet UILabel *rangeLable;
@property (weak, nonatomic) IBOutlet UISlider *rangeSlider;

@end

@implementation SettingViewController

@synthesize phoneNumberAlertView = _phoneNumberAlertView;
@synthesize referrerAlertView = _referrerAlertView;
@synthesize socket = _socket;
@synthesize pickerData = _pickerData;
@synthesize serverCitySelectActionSheet = _serverCitySelectActionSheet;


- (UIActionSheet *)serverCitySelectActionSheet
{
    if (_serverCitySelectActionSheet == nil)
    {
        _serverCitySelectActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:nil
                                         cancelButtonTitle:nil
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:nil];
        
        [_serverCitySelectActionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
        
        CGRect pickerFrame = CGRectMake(0, 40, 0, 0);
        
        UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
        pickerView.showsSelectionIndicator = YES;
        pickerView.dataSource = self;
        pickerView.delegate = self;
        pickerView.tag = 100;
        [_serverCitySelectActionSheet addSubview:pickerView];
        
        UISegmentedControl *closeButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"确定"]];
        closeButton.momentary = YES;
        closeButton.frame = CGRectMake(260, 7.0f, 50.0f, 30.0f);
        closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
        closeButton.tintColor = [UIColor blackColor];
        [closeButton addTarget:self action:@selector(dismissActionSheet:) forControlEvents:UIControlEventValueChanged];
        [_serverCitySelectActionSheet addSubview:closeButton];
        
        //[_serverCitySelectActionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
        
        //[_serverCitySelectActionSheet setBounds:CGRectMake(0, 0, 320, 485)];
    }
    return _serverCitySelectActionSheet;
}


- (NSArray *)pickerData
{
    if (_pickerData == nil)
    {
        _pickerData = [[NSArray alloc]initWithObjects:@"九江市",@"武汉市", nil];
    }
    return _pickerData;
}

- (AsyncUdpSocket *)socket
{
    if (_socket == nil)
    {
        _socket = [[AsyncUdpSocket alloc] initIPv4];
        _socket.delegate = self;
        _socket.maxReceiveBufferSize = 100;
        [self.socket receiveWithTimeout:-1 tag:0];
    }
    return _socket;
}


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


- (void)viewDidUnload
{
    self.socket = nil;
    [self setRangeLable:nil];
    [self setRangeSlider:nil];
    [super viewDidUnload];
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
            self.rangeLable.text = [NSString stringWithFormat:@"%d公里",[OperateAgreement Range]];
            self.rangeSlider.value = [OperateAgreement Range];
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
#pragma mark  serverCitySelectActionSheet delegate

- (void)dismissActionSheet:(id)sender
{
    [self.serverCitySelectActionSheet dismissWithClickedButtonIndex:0 animated:YES];
}

#pragma mark  Table view delegate



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 )
    {
        if (indexPath.row == 0)
        {
            [self.serverCitySelectActionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
            [self.serverCitySelectActionSheet setBounds:CGRectMake(0, 0, 320, 485)];
            UIPickerView *pickerView = (UIPickerView *)[self.serverCitySelectActionSheet viewWithTag:100];
            int value = [self.pickerData indexOfObject: [OperateAgreement ServerCityName]];        //someString 是我想让uipicerview自动选中的值
            [pickerView selectRow:value inComponent:0 animated:NO];
        }

        if (indexPath.row == 2)
        {
            [self.phoneNumberAlertView show];
        }
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
    
        if (![peopleName isEqualToString:[OperateAgreement Referrer]])
        {
            [OperateAgreement SetReferrer:peopleName];
            [self.tableView reloadData];
            NSData * data = [OperateAgreement GetUpdataReferrerData:peopleName];
            [self sendData:data];
        }


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


#pragma mark - Range Slider Value Change
- (IBAction)RangeSliderValueChange:(UISlider *)sender
{
    int discreteValue = roundl([sender value]); // Rounds float to an integer
    [sender setValue:(float)discreteValue];
    [OperateAgreement SetRange:discreteValue];
    self.rangeLable.text = [NSString stringWithFormat:@"%d公里",discreteValue];
}

#pragma mark - Picker Date Source Methods


-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.pickerData count];
}

#pragma mark Picker Delegate Methods


-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.pickerData objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString *serverCityName = [self.pickerData objectAtIndex:row];
    [OperateAgreement SetServerCityName:serverCityName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"当前城市：%@",serverCityName];

}


#pragma mark - UDP Delegate

- (void)sendData:(NSData * )data
{
    if (![Common isExistenceNetwork])
    {
        return;
    }
    if ([OperateAgreement UserPhoneNumber].length == 0)
    {
        return;
    }
    NSLog(@"%@",[OperateAgreement TaxiServerHost]);
    [self.socket sendData:data toHost:[OperateAgreement TaxiServerHost] port:UDP_TAXI_SERVER_PORT  withTimeout:1 tag:0];
    
    
}

//UDP接收消息
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    //---------Log
    NSString *info = [NSString stringWithFormat:@"host: %@,port : %hu",host,port];
    NSLog(@"%@",info);
    //启动监听下一条消息
    [self.socket receiveWithTimeout:-1 tag:0];
    
    BOOL isMessageStart = NO;
    
    NSMutableData *receData = [[NSMutableData alloc] init];
    for (int i = 0; i < data.length; i++)
    {
        Byte tmp = -1;
        [data getBytes:&tmp range:NSMakeRange(i, 1)];
        if (tmp == 0x7e)
        {
            isMessageStart = !isMessageStart;
        }
        if (isMessageStart)
        {
            [receData appendBytes:&tmp length:sizeof(Byte)];
        }
        if (isMessageStart == NO && tmp == 0x7e)
        {
            [receData appendBytes:&tmp length:sizeof(Byte)];
            NSData *oneMessage = [receData copy];
            receData.length = 0 ;
            NSData *realOneMessage =[OperateAgreement RestoreReceData:oneMessage];
            NSString *messageID = [OperateAgreement GetMessageIdInMessageHead:realOneMessage];
            NSLog(@"%@",messageID);
        }
    }
    

    
    
    return YES;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"Message not received for error: %@", error);
    self.socket = nil;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"Message not send for error: %@",error);
    self.socket = nil;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"Message send success!");
}

- (void)onUdpSocketDidClose:(AsyncUdpSocket *)sock
{
    self.socket = nil;
    NSLog(@"socket closed!");
}



@end
