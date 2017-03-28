//
//  ZXBDownloadMoudleManager.h
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/2/27.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZXBDownloadMoudle;
@class ZXBDownloadItem;

@interface ZXBDownloadMoudleManager : NSObject
+ (instancetype)sharedInstance;

- (void) registerMoudle:(ZXBDownloadMoudle*) moudle;
- (void) removeMoudle:(ZXBDownloadMoudle*) moudle;

//查询一个模块
- (ZXBDownloadMoudle*) moudleWithId:(NSString*) moudleId;

@end
