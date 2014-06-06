//
//  Branch_SDK.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "Branch.h"
#import "BranchServerInterface.h"
#import "PreferenceHelper.h"
#import "ServerRequest.h"

@interface Branch() <ServerInterfaceDelegate>

@property (strong, nonatomic) BranchServerInterface *bServerInterface;

@property (nonatomic) BOOL isInit;

@property (strong, nonatomic) NSMutableArray *uploadQueue;
@property (nonatomic) dispatch_semaphore_t processing_sema;
@property (nonatomic) NSInteger retryCount;
@property (nonatomic) NSInteger networkCount;

@end

@implementation Branch


static Branch *currInstance;

+ (Branch *)getInstance:(NSString *)key {
    if (!currInstance) {
        currInstance = [[Branch alloc] init];
        currInstance.isInit = false;
        currInstance.bServerInterface = [[BranchServerInterface alloc] init];
        currInstance.bServerInterface.delegate = currInstance;
        currInstance.processing_sema = dispatch_semaphore_create(1);
        currInstance.uploadQueue = [[NSMutableArray alloc] init];
        currInstance.retryCount = 0;
        currInstance.networkCount = 0;
    }
    return currInstance;
}

- (void)initUserSession {
    if (!self.isInit) {
        self.isInit = YES;
        [self initSession];
    }
}
/*
private void processNextQueueItem() {
    try {
        serverSema_.acquire();
        if (networkCount_ == 0 && requestQueue_.size() > 0) {
            networkCount_ = 1;
            serverSema_.release();
            
            ServerRequest req = requestQueue_.get(0);
            
            if (req.getTag().equals(BranchRemoteInterface.REQ_TAG_REGISTER_INSTALL)) {
                Log.i("AppidemicSDK", "calling register install");
                kRemoteInterface_.registerInstall(PrefHelper.NO_STRING_VALUE);
            } else if (req.getTag().equals(BranchRemoteInterface.REQ_TAG_REGISTER_OPEN)) {
                Log.i("AppidemicSDK", "calling register open");
                kRemoteInterface_.registerOpen();
            } else if (req.getTag().equals(BranchRemoteInterface.REQ_TAG_GET_REFERRALS) && hasUser()) {
                Log.i("AppidemicSDK", "calling get referrals");
                kRemoteInterface_.getReferrals();
            } else if (req.getTag().equals(BranchRemoteInterface.REQ_TAG_CREDIT_REFERRED) && hasUser()) {
                Log.i("AppidemicSDK", "calling credit referrals");
                kRemoteInterface_.creditUserForReferrals(req.getPost());
            } else if (req.getTag().equals(BranchRemoteInterface.REQ_TAG_COMPLETE_ACTION) && hasUser()){
                Log.i("AppidemicSDK", "calling completed action");
                kRemoteInterface_.userCompletedAction(req.getPost());
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    
}

private void retryLastRequest() {
    retryCount_ = retryCount_ + 1;
    if (retryCount_ > MAX_RETRIES) {
        requestQueue_.remove(0);
        retryCount_ = 0;
    } else {
        try {
            Thread.sleep(INTERVAL_RETRY);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}

private boolean installInQueue() {
    for (int i = 0; i < requestQueue_.size(); i++) {
        ServerRequest req = requestQueue_.get(i);
        if (req.getTag().equals(BranchRemoteInterface.REQ_TAG_REGISTER_INSTALL)) {
            return true;
        }
    }
    return false;
}

private void moveInstallToFront() {
    for (int i = 0; i < requestQueue_.size(); i++) {
        ServerRequest req = requestQueue_.get(i);
        if (req.getTag().equals(BranchRemoteInterface.REQ_TAG_REGISTER_INSTALL)) {
            requestQueue_.remove(i);
            break;
        }
    }
    requestQueue_.add(0, new ServerRequest(BranchRemoteInterface.REQ_TAG_REGISTER_INSTALL, null));
}

private boolean hasUser() {
    return !prefHelper_.getUserID().equals(PrefHelper.NO_STRING_VALUE);
}

private void registerInstall() {
    if (!installInQueue()) {
        requestQueue_.add(0, new ServerRequest(BranchRemoteInterface.REQ_TAG_REGISTER_INSTALL, null));
    } else {
        moveInstallToFront();
    }
    processNextQueueItem();
}

private void registerOpen() {
    requestQueue_.add(0, new ServerRequest(BranchRemoteInterface.REQ_TAG_REGISTER_OPEN, null));
    processNextQueueItem();
}

private void initSession() {
    if (hasUser()) {
        registerOpen();
    } else {
        registerInstall();
    }
}
*/
-(void)processReferralCounts:(NSDictionary *)returnedData {
    BOOL updateListener = false;
    
    for (NSString *key in returnedData) {
        if ([key isEqualToString:kpServerStatusCode] || [key isEqualToString:kpServerRequestTag])
            continue;
        
        NSDictionary *counts = [returnedData objectForKey:key];
        NSInteger total = [[counts objectForKey:@"total"] integerValue];
        NSInteger credits = [[counts objectForKey:@"credits"] integerValue];
        if (total != [PreferenceHelper getActionTotalCount:key] || credits != [PreferenceHelper getActionCreditCount:key]) {
            updateListener = YES;
        }
        [PreferenceHelper setActionTotalCount:key withCount:total];
        [PreferenceHelper setActionCreditCount:key withCount:credits];
        [PreferenceHelper setActionBalanceCount:key withCount:Math]
        prefHelper_.setActionTotalCount(key, total);
            prefHelper_.setActionCreditCount(key, credits);
            prefHelper_.setActionBalanceCount(key, Math.max(0, total-credits));
       	
    }
    if (updateListener) {
        if (self.delegate) {
            [self.delegate onStateChanged];
        }
    }
}

- (void)serverCallback:(NSDictionary *)returnedData {
    if (returnedData) {
        NSInteger status = [[returnedData objectForKey:kpServerStatusCode] integerValue];
        NSString *requestTag = [returnedData objectForKey:kpServerRequestTag];
        
        if ([requestTag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
            if (status == 200) {
    
            } else {
                
            }
        } else if ([requestTag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            
        } else if ([requestTag isEqualToString:REQ_TAG_GET_REFERRALS]) {
            
        } else if ([requestTag isEqualToString:REQ_TAG_CREDIT_ACTION]) {
            
        } else if ([requestTag isEqualToString:REQ_TAG_GET_CUSTOM_URL]) {
            
        }
    }
}

@end
