#include "Headers/Services/restrequest.h"
#include <QtNetwork>
#include <QString>

QMap<QString, QNetworkCookie> RestRequest::cookies;
bool RestRequest::m_sessionTimeout = true;

RestRequest::RestRequest() {}

RestRequest::~RestRequest() {}

bool RestRequest::isSessionTimeout() const{
    return RestRequest::m_sessionTimeout;
}

void RestRequest::login(QByteArray username, QByteArray password)
{
    QNetworkRequest request(QUrl("https://localhost/login"));

    QSslConfiguration conf = request.sslConfiguration();
    conf.setPeerVerifyMode(QSslSocket::VerifyNone);
    request.setSslConfiguration(conf);

    nam = new QNetworkAccessManager(this);

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

    reply = nam->post(request, multipart);
    connect(reply, &QNetworkReply::finished, this, &RestRequest::loginFinished);
}

void RestRequest::loginFinished()
{
    this->updateCookies();

    QVariant possibleRedirectUrl = reply->attribute(QNetworkRequest::RedirectionTargetAttribute);

    bool succeed = false;
    if (possibleRedirectUrl.toUrl().toString().endsWith("home")){
        RestRequest::m_sessionTimeout = false;
        succeed = true;
    }

    emit loginCompleted(succeed, reply->errorString());

    reply->deleteLater();
    nam->deleteLater();
}

void RestRequest::updateCookies()
{
    QList<QNetworkCookie> _cookies = qvariant_cast<QList<QNetworkCookie>>(
        reply->header(QNetworkRequest::SetCookieHeader));

    for (QNetworkCookie cookie : _cookies)
    {
        RestRequest::cookies.insert(QString::fromStdString(cookie.name().toStdString()), cookie);
    }
}

void RestRequest::get(QString url, QJSValue value) {
    this->get(url, QVariantMap(), value);
}

void RestRequest::get(QString url, QVariantMap params, QJSValue value) {
    nam = new QNetworkAccessManager(this);

    QUrl _url = QUrl("https://localhost/" + url);
    if (!params.isEmpty()) {
        QUrlQuery query(_url);

        for (auto key: params.keys()) {
            query.addQueryItem(key, params.value(key).toString());
        }
        _url.setQuery(query.query());
    }

    QNetworkRequest request = QNetworkRequest(_url);
    QSslConfiguration conf = request.sslConfiguration();
    conf.setPeerVerifyMode(QSslSocket::VerifyNone);
    request.setSslConfiguration(conf);
    request.setHeader(QNetworkRequest::CookieHeader, QVariant::fromValue(RestRequest::cookies.values()));

    reply = nam->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, value](){
        QVariant statusCode = this->reply->attribute( QNetworkRequest::HttpStatusCodeAttribute );
        if ( !statusCode.isValid() )
            return;
        if (300 <= statusCode.toInt() &&  statusCode.toInt() < 400)
        {
            QVariant possibleRedirectUrl =
                             this->reply->attribute(QNetworkRequest::RedirectionTargetAttribute);
            qDebug()<<possibleRedirectUrl.toString();
            if (possibleRedirectUrl.toString().contains("login"))
            {
                RestRequest::m_sessionTimeout = true;
                emit this->sessionTimeout();
                return;
            }
        }

        this->updateCookies();

        if (value.isCallable())
        {
            QJSValueList args;
            args.push_back(statusCode.toString());
            QString data = QString::fromStdString(reply->readAll().toStdString());
            args.push_back(data);

            QJSValue lValue(value);
            lValue.call(args);
            this->reply->deleteLater();
            this->nam->deleteLater();
        }
    });
}

void RestRequest::post(QString url, QJSValue value) {
    this->post(url, QVariantMap(), value);
}

void RestRequest::post(QString url, QVariantMap params, QJSValue value) {
    QNetworkRequest request(QUrl("https://localhost/" + url));

    QSslConfiguration conf = request.sslConfiguration();
    conf.setPeerVerifyMode(QSslSocket::VerifyNone);
    request.setSslConfiguration(conf);
    request.setHeader(QNetworkRequest::CookieHeader, QVariant::fromValue(RestRequest::cookies.values()));

    nam = new QNetworkAccessManager(this);

    QHttpMultiPart *multipart = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    params.insert("csrf_ospos_v3", RestRequest::cookies.value("csrf_cookie_ospos_v3").value());

    for (auto key: params.keys()) {
        QHttpPart paramPart;
        paramPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"" + key.toUtf8() + "\""));
        paramPart.setBody(params.value(key).toString().toUtf8());
        multipart->append(paramPart);
    }

    reply = nam->post(request, multipart);
    connect(reply, &QNetworkReply::finished, this, [this, value](){
        QVariant statusCode = this->reply->attribute( QNetworkRequest::HttpStatusCodeAttribute );
        if ( !statusCode.isValid() )
            return;
        if (300 <= statusCode.toInt() &&  statusCode.toInt() < 400)
        {
            QVariant possibleRedirectUrl =
                             this->reply->attribute(QNetworkRequest::RedirectionTargetAttribute);
            if (possibleRedirectUrl.toString().contains("login"))
            {
                RestRequest::m_sessionTimeout = true;
                emit this->sessionTimeout();
                return;
            }
        }

        this->updateCookies();
        if (value.isCallable())
        {
            QJSValueList args;
            args.push_back(statusCode.toString());
            QString data = QString::fromStdString(reply->readAll().toStdString());
            args.push_back(data);

            QJSValue lValue(value);
            lValue.call(args);
            this->reply->deleteLater();
            this->nam->deleteLater();
        }
    });
}
