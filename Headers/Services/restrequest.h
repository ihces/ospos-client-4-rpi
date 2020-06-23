#ifndef REST_REQUEST_H
#define REST_REQUEST_H

#include <QJSValue>
#include <QNetworkReply>
#include <QObject>
#include <QString>
#include <QLinkedList>
#include <QMutex>
#include <QTimer>

class RestRequest : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isSessionTimeout READ isSessionTimeout NOTIFY sessionTimeout)

public slots:
    void login(QByteArray username, QByteArray password);
    void get(QString url, QJSValue value);
    void get(QString url, QVariantMap params, QJSValue value);
    void post(QString url, QJSValue value);
    void post(QString url, QVariantMap params, QJSValue value);

signals:
    void loginCompleted(bool succeed, QString error=nullptr);
    void start();
    void end();
    void sessionTimeout();
    void requestTimeout();

public:
    RestRequest();
    bool isSessionTimeout() const;
    ~RestRequest();

private slots:
    void error(QNetworkReply::NetworkError code);

private:
    void updateCookies(QNetworkReply *reply);
    void clearFinishedReplies();
    void clearFinishedTimers();

private:
    static QByteArray csrf_ospos_v3;
    QLinkedList<QNetworkReply*> replyList;
    QLinkedList<QTimer*> timerList;
    static QMap<QString, QNetworkCookie> cookies;
    static QMutex cookieMutex;
    static bool m_sessionTimeout;
};
#endif // REST_REQUEST_H
