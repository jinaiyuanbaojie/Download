//
//  ZXBResourceDownloader.h
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/3/7.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZXBDownloadItem;
@protocol ZXBDownloadSessionDeleagte;

@interface ZXBResourceDownloader : NSObject <NSURLSessionDataDelegate>

-(instancetype) initWithDownloadItem:(ZXBDownloadItem*)item downloadDelegate:(id<ZXBDownloadSessionDeleagte>) delegate;

-(void) configNewDelegate:(id<ZXBDownloadSessionDeleagte>) delegate;
-(void) removeDelegate;

-(ZXBDownloadItem*) matchDownloadItem;
-(NSNumber*) taskIdentifier;

-(void) startUnderSession:(NSURLSession*) session;
-(void) cancel;

@end
