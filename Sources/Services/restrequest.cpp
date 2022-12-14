#include "Headers/Services/restrequest.h"
#include <QSettings>
#include <QtNetwork>
#include <QString>
#include <QLinkedList>
#include <QList>
#include <QTimer>

QMap<QString, QNetworkCookie> RestRequest::cookies;
QMutex RestRequest::cookieMutex;
bool RestRequest::m_sessionTimeout = true;
QByteArray RestRequest::csrf_ospos_v3 = "f422fcc283ce95334506eb40fa3628d8";

QSettings *settings;

RestRequest::RestRequest() {
    settings = new QSettings("posapp.ini", QSettings::NativeFormat);
    RestRequest::csrf_ospos_v3 = settings->value("CSRF_OSPOS_V3", "f422fcc283ce95334506eb40fa3628d8").toByteArray();
}

RestRequest::~RestRequest() {
    QLinkedList<QTimer*>::iterator iter;
    for (iter = timerList.begin(); iter != timerList.end(); ++iter)
        if ((*iter)->isActive()) {
            disconnect(*iter, &QTimer::timeout, this, nullptr);
            (*iter)->stop();
            emit this->end();
            iter = timerList.erase(iter);
        }
}

bool RestRequest::isSessionTimeout() const{
    return RestRequest::m_sessionTimeout;
}

void RestRequest::login(QByteArray username, QByteArray password)
{
    QNetworkRequest request(QUrl("https://3.123.73.136/login"));

    QSslConfiguration conf = request.sslConfiguration();
    conf.setPeerVerifyMode(QSslSocket::VerifyNone);
    request.setSslConfiguration(conf);

    QHttpMultiPart *multipart = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    QHttpPart csrf_ospos_v3Part;
    csrf_ospos_v3Part.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"csrf_ospos_v3\""));
    csrf_ospos_v3Part.setBody(RestRequest::csrf_ospos_v3);

    QHttpPart usernamePart;
    usernamePart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"username\""));
    usernamePart.setBody(username);

    QHttpPart passwordPart;
    passwordPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"password\""));
    passwordPart.setBody(password);

    multipart->append(csrf_ospos_v3Part);
    multipart->append(usernamePart);
    multipart->append(passwordPart);

    emit start();
    QNetworkAccessManager *nam = new QNetworkAccessManager(this);
    QNetworkReply *reply = nam->post(request, multipart);

    QTimer* timer4timeout = new QTimer();
    timer4timeout->setSingleShot(true);
    connect(timer4timeout, &QTimer::timeout,[this, reply]() {
        qDebug()<<"aaaaaaaaaaaaa";
        disconnect(reply, &QNetworkReply::finished, this, NULL);
        reply->abort();
        emit this->end();
        emit this->requestTimeout();
    });
    timer4timeout->start(5000);

    connect(reply, &QNetworkReply::finished, this, [this, reply, timer4timeout] {
        if (timer4timeout->isActive())
            timer4timeout->stop();

        this->updateCookies(reply);

        QVariant possibleRedirectUrl = reply->attribute(QNetworkRequest::RedirectionTargetAttribute);

        bool succeed = false;
        if (possibleRedirectUrl.toUrl().toString().endsWith("home")){
            RestRequest::m_sessionTimeout = false;
            succeed = true;
        }

        emit loginCompleted(succeed, reply->errorString());
        emit end();
    });

    clearFinishedReplies();
    replyList.append(reply);

    clearFinishedTimers();
    timerList.append(timer4timeout);
}

void RestRequest::updateCookies(QNetworkReply *reply)
{
    QList<QNetworkCookie> _cookies = qvariant_cast<QList<QNetworkCookie>>(
        reply->header(QNetworkRequest::SetCookieHeader));

    cookieMutex.lock();
    for (QNetworkCookie cookie : _cookies)
    {
        if (cookie.name() == "csrf_cookie_ospos_v3")
            settings->setValue("CSRF_OSPOS_V3", cookie.value());
        RestRequest::cookies.insert(QString::fromStdString(cookie.name().toStdString()), cookie);
    }
    cookieMutex.unlock();
}

void RestRequest::get(QString url, QJSValue value) {
    this->get(url, QVariantMap(), value);
}
void RestRequest::error(QNetworkReply::NetworkError code) {
    qDebug() << "QNetworkReply::NetworkError " << code << "received";
}
void RestRequest::get(QString url, QVariantMap params, QJSValue value) {
    QUrl _url = QUrl("https://3.123.73.136/" + url);
    if (!params.isEmpty()) {
        QUrlQuery query(_url);

        for (auto key: params.keys()) {
            if (params.value(key).type() == QVariant::Type::List){
                QList<QVariant> list = params.value(key).toList();
                if (list.isEmpty()) {
                    query.addQueryItem(key + "[]", "");
                    continue;
                }

                for (QList<QVariant>::const_iterator iter = list.begin(); iter != list.end(); ++iter)
                    query.addQueryItem(key + "[]", (*iter).toString().toUtf8());
            }
            else {
                query.addQueryItem(key, params.value(key).toString());
            }
        }
        _url.setQuery(query.query());
    }
    QNetworkRequest request = QNetworkRequest(_url);
    QSslConfiguration conf = request.sslConfiguration();
    conf.setPeerVerifyMode(QSslSocket::VerifyNone);
    request.setSslConfiguration(conf);
    request.setHeader(QNetworkRequest::CookieHeader, QVariant::fromValue(RestRequest::cookies.values()));
    emit start();
    QNetworkAccessManager *name = new QNetworkAccessManager(this);
    QNetworkReply *reply = name->get(request);

    QTimer* timer4timeout = new QTimer();
    timer4timeout->setSingleShot(true);
    connect(timer4timeout, &QTimer::timeout,[this, reply]() {
        disconnect(reply, &QNetworkReply::finished, this, NULL);
        reply->abort();
        emit this->end();
        emit this->requestTimeout();
    });
    timer4timeout->start(5000);

    connect(reply, &QNetworkReply::finished, this, [this, value, reply, timer4timeout](){
        if (timer4timeout->isActive())
            timer4timeout->stop();

        QVariant statusCode = reply->attribute( QNetworkRequest::HttpStatusCodeAttribute );
        if ( !statusCode.isValid() )
            return;
        if (300 <= statusCode.toInt() &&  statusCode.toInt() < 400)
        {
            QVariant possibleRedirectUrl =
                             reply->attribute(QNetworkRequest::RedirectionTargetAttribute);
            qDebug()<<possibleRedirectUrl.toString();
            if (possibleRedirectUrl.toString().contains("login"))
            {
                RestRequest::m_sessionTimeout = true;
                emit this->sessionTimeout();
                emit end();
                return;
            }
        }

        this->updateCookies(reply);
        if (value.isCallable())
        {
            QJSValueList args;
            args.push_back(statusCode.toString());
            QString data = QString::fromStdString(reply->readAll().toStdString());
            args.push_back(data);

            QJSValue lValue(value);
            lValue.call(args);
            emit end();
        }
    });

    clearFinishedReplies();
    replyList.append(reply);

    clearFinishedTimers();
    timerList.append(timer4timeout);
}

void RestRequest::clearFinishedReplies() {
    QLinkedList<QNetworkReply*>::iterator iter;

    for (iter = replyList.begin(); iter != replyList.end(); ++iter)
        if (!(*iter)->isRunning())
            iter = replyList.erase(iter);
}

void RestRequest::clearFinishedTimers() {
    QLinkedList<QTimer*>::iterator iter;
    for (iter = timerList.begin(); iter != timerList.end(); ++iter)
        if (!(*iter)->isActive())
            iter = timerList.erase(iter);
}

void RestRequest::post(QString url, QJSValue value) {
    this->post(url, QVariantMap(), value);
}

void RestRequest::post(QString url, QVariantMap params, QJSValue value) {
    QNetworkRequest request(QUrl("https://3.123.73.136/" + url));

    QSslConfiguration conf = request.sslConfiguration();
    conf.setPeerVerifyMode(QSslSocket::VerifyNone);
    request.setSslConfiguration(conf);
    request.setHeader(QNetworkRequest::CookieHeader, QVariant::fromValue(RestRequest::cookies.values()));

    QHttpMultiPart *multipart = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    params.insert("csrf_ospos_v3", RestRequest::cookies.value("csrf_cookie_ospos_v3").value());

    for (auto key: params.keys()) {
        if (params.value(key).type() == QVariant::Type::List){
            QList<QVariant> list = params.value(key).toList();
            if (list.isEmpty()) {
                QHttpPart paramPart;
                paramPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"" + key.toUtf8() + "[]\""));
                paramPart.setBody("");
                multipart->append(paramPart);
                continue;
            }

            for (QList<QVariant>::const_iterator iter = list.begin(); iter != list.end(); ++iter) {
                QHttpPart paramPart;
                paramPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"" + key.toUtf8() + "[]\""));
                paramPart.setBody((*iter).toString().toUtf8());
                multipart->append(paramPart);
            }
        }
        else {
            QHttpPart paramPart;
            paramPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"" + key.toUtf8() + "\""));
            paramPart.setBody(params.value(key).toString().toUtf8());
            multipart->append(paramPart);
        }
    }

    emit start();
    QNetworkAccessManager *nam = new QNetworkAccessManager(this);
    QNetworkReply *reply = nam->post(request, multipart);

    QTimer* timer4timeout = new QTimer();
    timer4timeout->setSingleShot(true);
    connect(timer4timeout, &QTimer::timeout,[this, reply]() {
        disconnect(reply, &QNetworkReply::finished, this, NULL);
        reply->abort();
        emit this->end();
        emit this->requestTimeout();
    });
    timer4timeout->start(5000);

    connect(reply, &QNetworkReply::finished, this, [this, value, reply, timer4timeout](){
        if (timer4timeout->isActive())
            timer4timeout->stop();

        QVariant statusCode = reply->attribute( QNetworkRequest::HttpStatusCodeAttribute );
        if ( !statusCode.isValid())
            return;
        if (300 <= statusCode.toInt() &&  statusCode.toInt() < 400)
        {
            QVariant possibleRedirectUrl =
                             reply->attribute(QNetworkRequest::RedirectionTargetAttribute);
            if (possibleRedirectUrl.toString().contains("login"))
            {
                RestRequest::m_sessionTimeout = true;
                emit this->sessionTimeout();
                emit end();
                return;
            }
        }

        this->updateCookies(reply);
        if (value.isCallable())
        {
            QJSValueList args;
            args.push_back(statusCode.toString());
            QString data = QString::fromStdString(reply->readAll().toStdString());
            args.push_back(data);

            QJSValue lValue(value);
            lValue.call(args);
            emit end();
        }
    });

    clearFinishedReplies();
    replyList.append(reply);

    clearFinishedTimers();
    timerList.append(timer4timeout);
}
