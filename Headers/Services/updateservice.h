#ifndef UPDATESERVICE_H
#define UPDATESERVICE_H

#include <QObject>
#include <QProcess>

class UpdateService: public QObject {
    Q_OBJECT

public:
    UpdateService();
    virtual ~UpdateService() {};
    Q_INVOKABLE void checkUpdate();
    Q_INVOKABLE void update();
signals:
    void checkUpdateFinished(bool upgradablePackFound);
    void updateFinished();

private:
    QProcess* process;
    bool upgradablePackFound;
    bool updateChecked;
};

#endif // UPDATESERVICE_H
