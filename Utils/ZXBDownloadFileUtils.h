//
//  ZXBDownloadFileUtils.h
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/3/7.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZXBDownloadItem;
@interface ZXBDownloadFileUtils : NSObject

+ (NSNumber*) freeDiskSpace;

+ (NSString*) targetFilePathWithItem:(ZXBDownloadItem*) item;

+ (NSString*) tempFilePathWithItem:(ZXBDownloadItem*) item;

+ (long long) getFileSizeAtPath:(NSString*) path;

+ (BOOL) isTargetFileExitWithItem:(ZXBDownloadItem*)item;

+ (BOOL) deleteTargetFileWithItem:(ZXBDownloadItem*)item;

@end
