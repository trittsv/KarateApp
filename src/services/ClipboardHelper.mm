// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "ClipboardHelper.hpp"
#include "utils/Logger.hpp"

#include <QApplication>
#include <QStyleHints>
#include <QDesktopServices>
#include <QUrl>

#ifdef Q_OS_IOS
#import <UIKit/UIKit.h>

static UIWindow *activeWindow() {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive
                || ![scene isKindOfClass:UIWindowScene.class]) {
                continue;
            }

            UIWindowScene *windowScene = static_cast<UIWindowScene *>(scene);
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow)
                    return window;
            }
        }
    }

    id<UIApplicationDelegate> appDelegate = UIApplication.sharedApplication.delegate;
    if ([appDelegate respondsToSelector:@selector(window)])
        return appDelegate.window;

    return nil;
}
#endif

void ClipboardHelper::shareUrl(const QString &url) {
#ifdef Q_OS_IOS
    NSURL *nsUrl = [NSURL URLWithString:url.toNSString()];
    if (!nsUrl)
        return;

    NSArray *items = @[nsUrl];

    UIActivityViewController *controller =
        [[UIActivityViewController alloc] initWithActivityItems:items
                                          applicationActivities:nil];

    UIWindow *window = activeWindow();
    if (!window)
        return;

    UIViewController *root = window.rootViewController;
    if (!root)
        return;

    while (root.presentedViewController) {
        root = root.presentedViewController;
    }

    [root presentViewController:controller animated:YES completion:nil];
#else
    QDesktopServices::openUrl(QUrl(url));
#endif
}
