//
//  SearchBusViewController.m
//  CallTaxi
//
//  Created by Fan Lv on 13-2-7.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import "SearchBusViewController.h"
#import "OperateAgreement.h"
#import "Common.h"
#import "TBXML.h"
#import "BusStationInfo.h"
#import "CustomAnnotationView.h"
#import "AsyncUdpSocket.h"
#import "BusInfo.h"
#import "NSData+Hex.h"
#import <MapKit/MapKit.h>
#import "fileOperate.h"
#import "SGInfoAlert.h"

@interface SearchBusViewController () <MKMapViewDelegate,UIGestureRecognizerDelegate>
{
    BOOL isFirstGetBusInfo;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong,nonatomic) AsyncUdpSocket *socket;
@property (strong,nonatomic) NSTimer *searchBusTimer;
@property (strong,nonatomic) NSArray *busList;

@end

@implementation SearchBusViewController

@synthesize socket = _socket;
@synthesize searchBusTimer = _searchBusTimer;

- (AsyncUdpSocket *)socket
{
    if (_socket == nil)
    {
        _socket = [[AsyncUdpSocket alloc] initIPv4];
        _socket.delegate = self;
        _socket.maxReceiveBufferSize = 1000;
        //绑定端口
        //NSError *error = nil;
        // [self.socket bindToPort:UDP_SEND_PORT error:&error];
        [self.socket receiveWithTimeout:-1 tag:0];
    }
    return _socket;
}

- (NSTimer *)searchBusTimer
{
    if (_searchBusTimer == nil)
    {
        _searchBusTimer = [NSTimer scheduledTimerWithTimeInterval:3
                                                           target:self
                                                         selector:@selector(searchBusThread:)
                                                         userInfo:nil
                                                          repeats:YES];
    }
    return  _searchBusTimer;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializationMapView];
    [self loadBusStationInfo];
    [self drawLineOnMap];
    isFirstGetBusInfo = YES;
    
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleWillResignActive)
                                                 name: UIApplicationWillResignActiveNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleDidBecomeActive)
                                                 name: UIApplicationDidBecomeActiveNotification 
                                               object: nil];
}

- (void)handleWillResignActive
{
    [self.searchBusTimer invalidate];
    self.searchBusTimer = nil;
    self.socket = nil;
}

- (void)handleDidBecomeActive
{
    if (_searchBusTimer == nil)
    {
        [self.searchBusTimer fire];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_searchBusTimer == nil)
    {
        [self.searchBusTimer fire];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.searchBusTimer invalidate];
    self.searchBusTimer = nil;
    self.socket = nil;
}




- (void)viewDidUnload
{
    self.socket = nil;
    [self setMapView:nil];
    [super viewDidUnload];
}


#pragma mark - SearchBusThread

-(void)searchBusThread:(NSTimer *)theTimer
{
    [self sendData:[OperateAgreement GetAllBusData]];
    
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
        NSLog(@"UserPhoneNumber =0");
        return;
    }
    [self.socket sendData:data toHost:[OperateAgreement BusServerHost] port:UDP_BUS_SERVER_PORT  withTimeout:1 tag:0];
    
}

//UDP接收消息
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    //---------Log
    NSString *info = [NSString stringWithFormat:@"host: %@,port : %hu",host,port];
    NSLog(@"%@",info);
//    [SGInfoAlert showInfo:info
//                  bgColor:[[UIColor darkGrayColor] CGColor]
//                   inView:self.view
//                 vertical:0.7];
    //启动监听下一条消息
    [self.socket receiveWithTimeout:-1 tag:0];
    
    BOOL isMessageStart = NO;
    
    
    NSMutableData *receData = [[NSMutableData alloc] init];
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    
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
            [dataArray addObject:realOneMessage];
        }
    }
    
    [self analysisMessage:dataArray];
    
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


#pragma mark Data Handling

- (void)analysisMessage:(NSArray *)dataArray
{
    NSData *realData = [dataArray objectAtIndex:0];
    if (![OperateAgreement JudgeisCompleteData:realData])
    {
        return;
    }
    NSString *messageID = [OperateAgreement GetMessageIdInMessageHead:realData];
    
    if ([messageID isEqual: MESSAGE_ID_GetAllBus_REPLY])
    {
        
        int taxiSumCount = 0;
        
        [self.mapView removeAnnotations:self.busList];
        NSMutableArray *busListTmp = [[NSMutableArray alloc] init];
        for (NSData *realData in dataArray)
        {
            NSUInteger len = [realData length];
            Byte *realDataByteArray = (Byte*)malloc(len);
            memcpy(realDataByteArray, [realData bytes], len);
            
            
            NSData *taxiCountData = [Common reversedData:[realData subdataWithRange:NSMakeRange(MESSAGE_BODY_START_INDEX, 2)]];
            ushort taxiCount =  *(const UInt16 *)[taxiCountData bytes];
            taxiSumCount += taxiCount;
            
            for (int i = 0; i < taxiCount; i++)
            {
                BusInfo *taxiInfo = [[BusInfo alloc] init];
                NSInteger taxiInfoStartIndex = MESSAGE_BODY_START_INDEX + 2 + (i*83);
                
                taxiInfo.longitude = [[[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex, 5)]
                                       hexRepresentationWithSpaces_AS:NO] doubleValue] / pow(10, 6);
                
                taxiInfo.latitude = [[[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex+5, 5)]
                                      hexRepresentationWithSpaces_AS:NO] doubleValue] / pow(10, 6);
                
                NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
                
                taxiInfo.busName = [[NSString alloc] initWithData:[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex + 10, 8)] encoding:enc];
                
                taxiInfo.angle = *(const UInt16 *)[[realData subdataWithRange:NSMakeRange(taxiInfoStartIndex + 18, 2)] bytes];
                
                taxiInfo.speed = realDataByteArray[taxiInfoStartIndex + 20];
                
                [busListTmp addObject:taxiInfo];
                
            }
            
            
        }
        
        self.busList = busListTmp;
        
        [self.mapView addAnnotations:self.busList];
        
        if (isFirstGetBusInfo)
        {
            isFirstGetBusInfo = NO;
            MKMapRect zoomRect = MKMapRectNull;
            for (id <MKAnnotation> annotation in self.mapView.annotations)
            {
                if ([annotation isKindOfClass:[BusInfo class]])
                {
                    if (annotation.coordinate.latitude < 20 || annotation.coordinate.longitude < 100)
                        continue;
                    MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
                    MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
                    zoomRect = MKMapRectUnion(zoomRect, pointRect);
                }
            }
            [self.mapView setVisibleMapRect:zoomRect animated:YES];
        }
        
    }
    
}


#pragma mark - Show BusStationName


- (IBAction)showBusStationName:(UIBarButtonItem *)sender
{
    if ([sender.title isEqualToString:@"显示站点信息"])
    {
        [self.mapView addAnnotations:self.busStationInfoList];
        sender.title = @"不显示站点信息";
    }
    else
    {
        [self.mapView removeAnnotations:self.busStationInfoList];
        sender.title = @"显示站点信息";
    }
    NSLog(@"%f,%f",self.mapView.centerCoordinate.latitude,self.mapView.centerCoordinate.longitude);
    
//    fileOperate  *file=[[fileOperate alloc]init];
//    NSString *filePath=[file getFilePath:@"CallTaxiRecord.csv"];
//    [file deleteFile:filePath];
    
    
}


#pragma - mark InitializationMapView


- (void)initializationMapView
{
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate = self;
    self.mapView.userLocation.title = @"我的位置";
    
    //29.249560,115.799255
    double longitude = 115.799255;
    double latitude = 29.249560;
    CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(latitude,longitude);
    float zoomLevel = 0.03;
    MKCoordinateRegion region = MKCoordinateRegionMake(coords, MKCoordinateSpanMake(zoomLevel, zoomLevel));
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
}


- (void)drawLineOnMap
{
    for (int i = 1; i <= 3; i++)
    {
        NSError *error = nil;
        
        NSString *fileName = [NSString stringWithFormat:@"route%d.xml",i];
        TBXML *tbxml = [[TBXML alloc] initWithXMLFile:fileName error:&error];
        
        TBXMLElement *root = tbxml.rootXMLElement;
        NSMutableArray *points = [NSMutableArray array];
        if (root)
        {
            TBXMLElement *station = [TBXML childElementNamed:@"Point" parentElement:root];
            while (station)
            {
                double lat = [[TBXML valueOfAttributeNamed:@"Lng" forElement:station] doubleValue];
                double lng = [[TBXML valueOfAttributeNamed:@"Lat" forElement:station] doubleValue];
                CLLocation *cl = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
                [points addObject:cl];
                station = [TBXML nextSiblingNamed:@"Point" searchFromElement:station];
            }
            
        }
        if (points.count > 0)
        {
            CLLocationCoordinate2D coordinates[points.count];
            for (NSInteger index = 0; index < points.count; index++)
            {
                CLLocation *location = [points objectAtIndex:index];
                CLLocationCoordinate2D coordinate = location.coordinate;
                coordinates[index] = coordinate;
            }
            
            MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:points.count];
            polyLine.title = [NSString stringWithFormat:@"line%d",i];
            [self.mapView addOverlay:polyLine];
        }
        
    }
}



- (void)loadBusStationInfo
{
    NSError *error = nil;
    
    // Load and parse an xml string
    TBXML *tbxml = [[TBXML alloc] initWithXMLFile:@"gongqingstations.xml" error:&error];
    
    
    //tbxml = [TBXML tbxmlWithXMLFile:@"books.xml"];
    
    TBXMLElement *root = tbxml.rootXMLElement;
    
    if (root)
    {
        NSMutableArray *busListTmp = [NSMutableArray array];
        TBXMLElement *station = [TBXML childElementNamed:@"station" parentElement:root];
        while (station)
        {
            BusStationInfo *busStationInfo = [[BusStationInfo alloc] init];
            TBXMLElement *name = [TBXML childElementNamed:@"name" parentElement:station];
            TBXMLElement *lat = [TBXML childElementNamed:@"lat" parentElement:station];
            TBXMLElement *lng = [TBXML childElementNamed:@"lng" parentElement:station];
            TBXMLElement *line = [TBXML childElementNamed:@"line" parentElement:station];
            
            busStationInfo.stationName = [TBXML textForElement:name];
            busStationInfo.latitude = [[TBXML textForElement:lat] doubleValue];
            busStationInfo.longitude = [[TBXML textForElement:lng] doubleValue];
            busStationInfo.lineName = [TBXML textForElement:line];
            
            station = [TBXML nextSiblingNamed:@"station" searchFromElement:station];
            
            [busListTmp addObject:busStationInfo];
        }
        
        self.busStationInfoList = busListTmp;
    }
    
    
    tbxml = nil;
}







#pragma mark - MKMapView Delegate


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[BusStationInfo class]]) // 处理公交车站点
    {
        BusStationInfo* busStationAnnotation= annotation;
        CustomAnnotationView *annotationView = [[CustomAnnotationView alloc] initWithAnnotation:busStationAnnotation reuseIdentifier:@"station"];
        //annotationView.canShowCallout = YES;
        return annotationView;
        
    }
    if ([annotation isKindOfClass:[BusInfo class]])
    {
        BusInfo *taxiInfo = annotation;
        MKAnnotationView *aView=[mapView dequeueReusableAnnotationViewWithIdentifier:@"bus"];
        if (!aView)
        {
            aView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"bus"];
            aView.canShowCallout = YES;
            
            aView.image = [OperateAgreement GetBusImageWithAngle:taxiInfo.angle];
            aView.frame = CGRectMake(0, 0, 40, 20);
            aView.calloutOffset = CGPointMake(2,0);
            
        }
        return aView;
    }
    
    return nil;
}


- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    
    MKPolylineView *polylineView = [[MKPolylineView alloc] initWithPolyline:overlay];
    polylineView.strokeColor = [UIColor redColor];
    polylineView.lineWidth = 4.0;
    
    if ([overlay.title isEqualToString:@"line1"])
        polylineView.strokeColor=[UIColor greenColor];
    else if ([overlay.title isEqualToString:@"line2"])
        polylineView.strokeColor=[UIColor purpleColor];
    else
        polylineView.strokeColor=[UIColor blueColor];
    
    return polylineView;
}



@end
