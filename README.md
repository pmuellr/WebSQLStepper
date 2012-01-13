WebSQLStepper
=============

A simple layer over Web SQL to help avoid callback hell.  It's pretty simple,
you wiill still have to have some familiarity with the [WebSQL][] API.

api
===

WebSQLStepper global object
-----------------------------

The global variable `WebSQLStepper` provides a single method to invoke
a transaction.

**`transaction(db, steps)`**

> **parameters**

> * `db` is an instance of the Web SQL `Database` interface
> * `steps` is an instance of the `Steps` interface

> Runs the steps in a `steps` object as a transaction.

Steps interface
-----------------

A `Steps` object is an object you create that provides the methods listed
below.  Your `Steps` object is passed to `WebSQLStepper.transaction()` and
will then have it's methods invoked to execute the transaction.

All the methods invoked on a `Steps` object pass the `Steps` object
as the `this` value.

**`success()`**

> This function will be invoked if the transaction completes successfully.

**`error(sqlError)`**

> **parameters**

> * `sqlError` is an instance of a Web SQL SqlError interface

> This function will be invoked if the transaction does not complete successfully.

**`step#(transaction, sqlError, resultSet)`**

> **parameters**

> * `transaction` is an instance of a `Transaction` interface
> * `sqlError` is an instance of a Web SQL SqlError interface
> * `resultSet` is an instance of a Web SQL SqlResultSet interface

> The `Steps` object can have multiple step methods, each named as
> `step1`, `step2`, and so on.  The steps will be executed in sequence,
> starting at `step1` working up to the last step.  Each step must make one
> call to the `tx.executeSql()` method.  The results of executing that
> SQL statement will be passed to the next step in it's arguments - the
> `sqlError` in case an error occurred while executing the statement, or
> the `resultSet` object in the case the statement executed successfully.
> When all of the statements have completed, either the `success()` or
> `error()` method of the `Steps` object will be invoked.

> A `Steps` object may also have a property `stepsName`, which can be used
> to describe the object in diagnostics.

Transaction interface
-----------------------

The `transaction` parameter passed to a step is used to execute SQL
statements.

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

[WebSQL]: http://www.w3.org/TR/webdatabase/ "WebSQL specification"
[SQLite]: http://www.sqlite.org/docs.html   "SQLite documentation"

* [Web SQL Database specification][WebSQL]
* [SQLite documentation][SQLite]

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
