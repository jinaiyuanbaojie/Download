//
//  ZXBDownloadMoudle.h
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/2/27.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 知学宝内每一个下载业务对应一个moudle
 */
@class ZXBDownloadItem;
@interface ZXBDownloadMoudle : NSObject

@property (nonatomic,copy)                  NSString    *moudleId;
@property (nonatomic,copy)                  NSString    *tmpPath; //配置相对路径名，iOS8以后沙盒的文件路径会动态改变
@property (nonatomic,copy)                  NSString    *targetPath;//配置相对路径名，iOS8以后沙盒的文件路径会动态改变

-(instancetype) initWithMoudleId:(NSString*) moudleId;
@end
