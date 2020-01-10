#ifndef REST_REQUEST_H
#define REST_REQUEST_H

#include <QJSValue>
#include <QNetworkReply>
#include <QObject>
#include <QString>

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
    void sessionTimeout();

public:
    RestRequest();
    bool isSessionTimeout() const;
    ~RestRequest();

private slots:
    void loginFinished();

private:
    void updateCookies();

private:
    const QByteArray csrf_ospos_v3 = "f422fcc283ce95334506eb40fa3628d8";
    QNetworkReply *reply;
    QNetworkAccessManager *nam;
    static QMap<QString, QNetworkCookie> cookies;
    static bool m_sessionTimeout;
};
#endif // REST_REQUEST_H
