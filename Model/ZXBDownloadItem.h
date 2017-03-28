//
//  ZXBDownloadItem.h
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/2/27.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZXBDownloadState.h"

@interface ZXBDownloadItem : NSObject
@property (nonatomic,copy,readonly)     NSString            *itemId; //下载资源的ID
@property (nonatomic,assign)            ZXBDownloadState    state;
@property (nonatomic,assign)            double              downloadProgress;
@property (nonatomic,copy,readonly)     NSString            *downloadUrl;
@property (nonatomic,copy)              NSString            *fileName; //if nil we will use suggest name
@property (nonatomic,copy)              NSString            *tmpFilePath; //配置相对路径名，iOS8以后沙盒的文件路径会动态改变
@property (nonatomic,copy)              NSString            *targetPath; //配置相对路径名，iOS8以后沙盒的文件路径会动态改变
@property (nonatomic,copy,readonly)     NSString            *moudleId;
@property (nonatomic,assign)            double              timeStamp;//时间戳

- (instancetype) initWithItemId:(NSString*) itemId moudleId:(NSString*) moudleId url:(NSString*) downloadUrl;

#pragma mark - database
- (NSString*) resourceId;
- (NSString*) userId;
@end
