//
//  ZXBDownloadFileUtils.m
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/3/7.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import "ZXBDownloadFileUtils.h"
#import "ZXBDownloadMoudleManager.h"
#import "ZXBDownloadItem.h"
#import "ZXBDownloadMoudle.h"

@implementation ZXBDownloadFileUtils

+ (NSNumber*) freeDiskSpace{
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [fattributes objectForKey:NSFileSystemFreeSize];
}

+ (NSString*) targetFilePathWithItem:(ZXBDownloadItem*) item{
    NSString *relativePath = @"zxbDownload";

    NSString *moudleTargetPath = [[ZXBDownloadMoudleManager sharedInstance] moudleWithId:item.moudleId].targetPath;
    if(moudleTargetPath){
        relativePath = moudleTargetPath;
    }
    
    if (item.targetPath) {
        relativePath = item.targetPath;
    }
    
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:relativePath];
}

+ (NSString*) tempFilePathWithItem:(ZXBDownloadItem*) item{
    NSString *relativePath = @"zxbCache";

    NSString *moudleTmpPath = [[ZXBDownloadMoudleManager sharedInstance] moudleWithId:item.moudleId].tmpPath;
    if(moudleTmpPath){
        relativePath = moudleTmpPath;
    }
    
    if (item.tmpFilePath) {
        relativePath = item.tmpFilePath;
    }
    
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:relativePath];
}

+ (long long) getFileSizeAtPath:(NSString*) path{
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
}

+ (BOOL) isTargetFileExitWithItem:(ZXBDownloadItem*)item{
    if (!item.fileName) {
        return NO;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *dirPath = [self targetFilePathWithItem:item];
    NSString *totalTargetPath = [NSString stringWithFormat:@"%@/%@",dirPath,item.fileName];

    return [fm fileExistsAtPath:totalTargetPath];
}

+ (BOOL) deleteTargetFileWithItem:(ZXBDownloadItem*)item{
    if (!item.fileName) {
        return YES;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *dirPath = [self targetFilePathWithItem:item];
    NSString *totalTargetPath = [NSString stringWithFormat:@"%@/%@",dirPath,item.fileName];
    
    return [fm removeItemAtPath:totalTargetPath error:nil];
}

@end
