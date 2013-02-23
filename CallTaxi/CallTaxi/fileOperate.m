//
//  fileOperate.m
//  Surver
//
//  Created by otech on 12-12-14.
//  Copyright (c) 2012年 otech. All rights reserved.
//
//对Document目录下文件操作
#import "fileOperate.h"

@implementation fileOperate
//保存文件
-(BOOL)saveFile:(NSString*)filePath withAppendString:(NSString*)str
{
    NSString *csvLine=[NSString stringWithFormat:@"%@\n",str];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    }
    NSFileHandle *file=[NSFileHandle fileHandleForUpdatingAtPath:filePath];
    [file seekToEndOfFile];
    [file writeData:[csvLine dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
    
    return true;
}
//读取文件
-(NSString *)loadFile:(NSString*)filePath
{
    NSString *resultStr=nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSFileHandle *file=[NSFileHandle fileHandleForReadingAtPath:filePath];
        resultStr=[[NSString alloc] initWithData:[file availableData] encoding:NSUTF8StringEncoding];
        [file closeFile];
    }
    return resultStr;
}
//获取文件路径
-(NSString*)getFilePath:(NSString*)fileName
{
    NSString *docDir=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath=[docDir stringByAppendingPathComponent:fileName];
    return filePath;
}
//删除文件
-(void)deleteFile:(NSString*)filePath
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:filePath])
    {
        if ([fileMgr removeItemAtPath:filePath error:nil] )
        {
            NSLog(@" delete file");
        }
    }
}
@end
