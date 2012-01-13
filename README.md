WebSQLStepper
=============

A simple layer over Web SQL to help avoid callback hell.  It's a pretty thin layer,
so you will still have to have familiarity with the [WebSQL][] API.

api
===

WebSQLStepper global object
-----------------------------

The global variable `WebSQLStepper` provides a single method to invoke
a transaction.

**`transaction(db, steps)`**

> **parameters**

> * `db` is an instance of the Web SQL <tt>[Database][]</tt> interface
> * `steps` is an instance of the `Steps` interface

> Runs the steps in the `steps` parameter as a transaction.

Steps interface
-----------------

A `Steps` object is an object you create that provides the methods listed
below.  You pass your `Steps` object to `WebSQLStepper.transaction()` and
then the `Steps` objects' methods will be called during the lifetime of the
transaction.

All the methods invoked on a `Steps` object pass the `Steps` object itself
as the `this` value.

A `Steps` object may also have a property `stepsName`, which is be used
to describe the object in diagnostics.

**`success()`**

> This function will be invoked if the transaction completes successfully.

**`error(sqlError)`**

> **parameters**

> * `sqlError` is an instance of a Web SQL <tt>[SQLError][]</tt> interface

> This function will be invoked if the transaction does not complete successfully.

**`step#(transaction, sqlError, resultSet)`**

> **parameters**

> * `transaction` is an instance of a `Transaction` interface
> * `sqlError` is an instance of a Web SQL <tt>[SQLError][]</tt> interface
> * `resultSet` is an instance of a Web SQL <tt>[SQLResultSet][]</tt> interface

> The `Steps` object can have multiple step methods, each named as
> `step1`, `step2`, and so on.  The steps will be executed in sequence,
> starting at `step1` working up to the last step.  Each step must make one
> call to the `transaction.executeSql()` method.  The results of executing that
> SQL statement will be passed to the next step in it's arguments - the
> `sqlError` in case an error occurred while executing the statement, or
> the `resultSet` object in the case the statement executed successfully.
> When all of the statements have completed, either the `success()` or
> `error()` method of the `Steps` object will be invoked.

Transaction interface
-----------------------

The `transaction` parameter passed to a step is used to execute SQL
statements.  It is an analogue of the Web SQL <tt>[SQLTransaction][]</tt>
interface.

**`executeSql(sqlStatement, arguments)`**

> **parameters**

> * `sqlStatement` is SQL statement as a string
> * `arguments` is an array of values to be used in the `?` placeholders in the `sqlStatement`


examples
========

    WebSQLStepper.transaction database,
        stepsName: 'create'

        #----------------------------------
        error: (sqlError) ->
            store.error(sqlError, options)

        #----------------------------------
        step1: (tx) ->
            data = JSON.stringify(model.toJSON())
            tx.executeSql 'INSERT INTO store VALUES(NULL, ?)', [data]

        #----------------------------------
        step2: (tx, sqlError, resultSet) ->
            return if sqlError

            @id = resultSet.insertId

        #----------------------------------
        success: ->
            model.id = @id
            options.success model

references
==========

* [Web SQL Database specification][WebSQL]
* [SQLite documentation][SQLite]

[SQLite]:         http://www.sqlite.org/docs.html                  "SQLite documentation"
[WebSQL]:         http://www.w3.org/TR/webdatabase/                "WebSQL specification"
[Database]:       http://www.w3.org/TR/webdatabase/#database       "WebSQL Database interface"
[SQLTransaction]: http://www.w3.org/TR/webdatabase/#sqltransaction "WebSQL SQLTransaction interface"
[SQLResultSet]:   http://www.w3.org/TR/webdatabase/#sqlresultset   "WebSQL SQLResultSet interface"
[SQLError]:       http://www.w3.org/TR/webdatabase/#sqlerror       "WebSQL SQLError interface"

license / copyright
===================

Copyright (c) 2012 Patrick Mueller

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
