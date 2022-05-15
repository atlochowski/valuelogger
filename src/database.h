/*
Copyright (c) 2021-2022 Slava Monich <slava@monich.com>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

#ifndef DATABASE_H
#define DATABASE_H

#include <QSharedPointer>
#include <QVariantList>
#include <QDateTime>
#include <QString>
#include <QObject>

/* Parameter table */
#define PARAMETER_COL       "parameter"     /* TEXT */
#define DESCRIPTION_COL     "description"   /* TEXT */
#define VISUALIZE_COL       "visualize"     /* INTEGER */
#define PLOTCOLOR_COL       "plotcolor"     /* TEXT */
#define DATATABLE_COL       "datatable"     /* TEXT */
#define PAIREDTABLE_COL     "pairedtable"   /* TEXT */

/* Data table */
#define DATA_KEY_COL        "key"           /* TEXT */
#define DATA_TIMESTAMP_COL  "timestamp"     /* TEXT */
#define DATA_VALUE_COL      "value"         /* TEXT */
#define DATA_ANNOTATION_COL "annotation"    /* TEXT */

#define NAME_ROLE           "name"
#define DESCRIPTION_ROLE    DESCRIPTION_COL
#define VISUALIZE_ROLE      VISUALIZE_COL
#define PLOTCOLOR_ROLE      PLOTCOLOR_COL
#define DATATABLE_ROLE      DATATABLE_COL
#define PAIREDTABLE_ROLE    PAIREDTABLE_COL

#define DATA_KEY_ROLE       DATA_KEY_COL
#define DATA_TIMESTAMP_ROLE DATA_TIMESTAMP_COL
#define DATA_TIMESTAMP_UTC_ROLE "timestampUTC"
#define DATA_VALUE_ROLE     DATA_VALUE_COL
#define DATA_ANNOTATION_ROLE DATA_ANNOTATION_COL

class Database : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY(Database)
    class Private;

public:
    Database(QObject* parent);
    ~Database();

    static QDateTime toDateTime(const QVariant& value);
    static QString toString(const QDateTime& value);

    QVariantList readParameters();
    QVariantList readData(QString table);
    QString addParameter(QString name, QString description, bool visualize, QString plotcolor);
    QString addData(QString table, QString key, QString value, QString annotation, QString timestamp);
    bool insertOrReplace(QString datatable, QString name, QString description, bool visualize, QString plotColor, QString pairedtable);
    bool setPairedTable(QString datatable, QString pairedtable);
    void deleteData(QString table, QString key);
    void deleteParameter(QString datatable);

signals:
    void dataChanged(QString datatable);

private:
    QSharedPointer<Private> p;
};

#endif // DATABASE_H
