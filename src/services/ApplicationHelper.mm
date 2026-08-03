// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>

void requestNativeAppReview() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 14.0, *)) {
            UIWindowScene *activeScene = nil;

            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive
                    && [scene isKindOfClass:UIWindowScene.class]) {
                    activeScene = static_cast<UIWindowScene *>(scene);
                    break;
                }
            }

            if (activeScene != nil)
                [SKStoreReviewController requestReviewInScene:activeScene];
        }
    });
}
