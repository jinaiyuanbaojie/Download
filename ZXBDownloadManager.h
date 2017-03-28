//
//  ZXBTestDownloadManager.h
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/3/7.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 模拟器测试可能会发生崩溃 关闭Scheme->Run->Queue Debugging 即可。
 * @see http://stackoverflow.com/questions/40371536/nsurlsession-causing-exc-bad-access
 * @see http://stackoverflow.com/questions/34336920/memory-leak-with-libbacktracerecording-dylib-in-react-native-ios-application
 */

@protocol ZXBDownloadSessionDeleagte <NSObject>
- (void) notifyDownloadResultWithError:(NSError*) error item:(ZXBDownloadItem*) item;
- (void) notifyDownloadItemProgress:(ZXBDownloadItem*) item;
@end

extern NSString *const ZXBDownloadErrorDomain;
@class ZXBDownloadItem;

@interface ZXBDownloadManager : NSObject

+ (instancetype)sharedInstance;

#pragma mark -

- (void) startWithItem:(ZXBDownloadItem*) item;
- (void) resumeWithItem:(ZXBDownloadItem*) item;
- (void) pauseWithItem:(ZXBDownloadItem*) item;
- (void) cancelWithItem:(ZXBDownloadItem*) item;

#pragma mark - 
- (void) registerDownloadDelegate:(id<ZXBDownloadSessionDeleagte>) delegate forMoudle:(NSString*) moudleId;
- (void) removeDownloadDelegateForMoudle:(NSString*) moudleId;
- (NSInteger) currentDownloadNumUnderMoudle:(NSString*) moudleId;
- (NSArray<ZXBDownloadItem*>*) unCompleteItemsUnderMoudle:(NSString*) moudleId; //缓存在数据库中未完成的历史任务
@end
