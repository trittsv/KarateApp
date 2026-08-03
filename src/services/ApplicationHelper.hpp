// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QObject>

class ApplicationHelper : public QObject {
    Q_OBJECT

public:
    explicit ApplicationHelper(QObject *parent = nullptr);

    Q_INVOKABLE void moveToBackground();
    Q_INVOKABLE void requestAppReview();
};
