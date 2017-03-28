//
//  ZXBDownloadDataBaseManager.h
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/3/10.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZXBDownloadItem;
@interface ZXBDownloadDatabaseManager : NSObject
- (void) deleteItem:(ZXBDownloadItem*) item;
- (void) addItem:(ZXBDownloadItem*) item;
- (NSArray*) queryAllWithMoudleId:(NSString*) moudleId userId:(NSString*) userId;
@end
