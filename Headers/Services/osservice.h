#ifndef OSSERVICE_H
#define OSSERVICE_H

#include <QObject>
#include <QProcess>

class OsService: public QObject {
    Q_OBJECT

public:
    OsService();
    virtual ~OsService() {};
    Q_INVOKABLE void shutdown();
    Q_INVOKABLE void restart();
};

#endif // OSSERVICE_H
