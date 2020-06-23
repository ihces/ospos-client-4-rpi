#include "Headers/Services/updateservice.h"
#include <QDebug>

UpdateService::UpdateService() {
    process = new QProcess();
}

void UpdateService::checkUpdate() {
    if (process->state() == QProcess::Running)
        return;

    connect(process, &QProcess::readyRead, this, [this] {
        QByteArray readStr = process->readAll();

        if (updateChecked)
            upgradablePackFound = readStr.contains("posapp");

        if (readStr.contains("All packages are up to date")) {
            updateChecked = true;

        }
        else if (readStr.contains("packages can be upgraded") || readStr.contains("Some index files failed to download")) {
            updateChecked = true;
        }
    });

    connect(process, &QProcess::readChannelFinished, this, [this] {
        if (updateChecked) {
            qDebug()<<"Updates Checked. New Pack Found? " << upgradablePackFound;
            emit checkUpdateFinished(upgradablePackFound);
        }
    });

    process->start("/bin/bash", QStringList() << "-c" << "apt update && apt-get -u upgrade --assume-no");
}

void UpdateService::update() {
    if (process->state() == QProcess::Running || !updateChecked || !upgradablePackFound)
        return;

    connect(process, &QProcess::readChannelFinished, this, [this] {
        qDebug()<<"Update Finished";
        emit updateFinished();
    });

    QStringList args;
    args << "upgrade" << "-y";
    process->start("/usr/bin/apt", args);
}
