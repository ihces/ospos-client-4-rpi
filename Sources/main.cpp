#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "Headers/Services/restrequest.h"
#include "Headers/Services/updateservice.h"
#include "Headers/Services/osservice.h"
#include <QCursor>

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    qmlRegisterType<RestRequest>("posapp.restrequest", 1, 0, "RestRequest");
    qmlRegisterType<UpdateService>("posapp.updateservice", 1, 0, "UpdateService");
    qmlRegisterType<OsService>("posapp.osservice", 1, 0, "OsService");

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    QCursor cursor;
    cursor.setPos(800, 480);

    return app.exec();
}
