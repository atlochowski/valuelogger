/*
Copyright (c) 2021 Slava Monich <slava@monich.com>

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

#ifndef DATATABLEMODEL_H
#define DATATABLEMODEL_H

#include "datamodel.h"
#include "database.h"

class DataTableModel : public DataModel
{
    Q_OBJECT
    Q_PROPERTY(QString dataTable READ getDataTable WRITE setDataTable NOTIFY dataTableChanged)

public:
    explicit DataTableModel(QObject* parent = Q_NULLPTR);
    ~DataTableModel();

    QString getDataTable() const { return m_dataTable; }
    void setDataTable(QString table);

    Q_INVOKABLE void reset();

protected:
    void deleteRowStorage(QString key) Q_DECL_OVERRIDE;
    bool updateRowStorage(QString key, QString value, QString annotation, QString timestamp) Q_DECL_OVERRIDE;

signals:
    void dataTableChanged();

private:
    Database m_db;
    QString m_dataTable;
};

#endif // DATATABLEMODEL_H
