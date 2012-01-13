###
# Copyright (c) 2012 Patrick Mueller
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###

#-------------------------------------------------------------------------------
# external interfaces we need to support:
#  - todos.js calls `new Store("todos")` and sets it as the property
#    localStorage on the TodoList class (a Collection)
#  - implement Backbone.sync = function(method, model, options)
#      method = read | create | update | delete
#      options =
#         succcess: (model|model[])->
#         error:    (message) ->
#-------------------------------------------------------------------------------

Stores = {}

#-------------------------------------------------------------------------------
# similar to original Todo Backbone.sync
#-------------------------------------------------------------------------------
Backbone.sync = (method, model, options) ->

    store = model.localStorage || model.collection.localStorage;

    if not store.tableCreated
        return store.createTableThenSync(method, model, options)

    switch method
        when "read"
            if model.id?
                store.read(model, options)
            else
                store.readAll(options)

        when "create"
            store.create(model, options)

        when "update"
            store.update(model, options)

        when "delete"
            store.delete(model, options)

#-------------------------------------------------------------------------------
window.Store = class Store

    #---------------------------------------------------------------------------
    constructor: (@name) ->
        return Stores[@name] if Stores[@name]
        Stores[@name] = this

        @tableCreated = false

        @openDatabase()

    #---------------------------------------------------------------------------
    openDatabase: ->
        wdbName    = "#{@name}"
        wdbComment = "#{@name}"
        wdbSize    = 1*1024*1024

        @wdb = window.openDatabase(wdbName, '', wdbComment, wdbSize)

    #---------------------------------------------------------------------------
    createTableThenSync: (method, model, options) ->
        WebSQLStepper.transaction @wdb, new CreateTableThenSyncSteps(@, model, options, method)

    #---------------------------------------------------------------------------
    create: (model, options) ->
        WebSQLStepper.transaction @wdb, new CreateSteps(@, model, options)

    #---------------------------------------------------------------------------
    read: (model, options) ->
        WebSQLStepper.transaction @wdb, new ReadSteps(@, model, options)

    #---------------------------------------------------------------------------
    readAll: (options) ->
        WebSQLStepper.transaction @wdb, new ReadAllSteps(@, null, options)

    #---------------------------------------------------------------------------
    update: (model, options) ->
        WebSQLStepper.transaction @wdb, new UpdateSteps(@, model, options)

    #---------------------------------------------------------------------------
    delete: (model, options) ->
        WebSQLStepper.transaction @wdb, new DeleteSteps(@, model, options)

#-------------------------------------------------------------------------------
class Steps

    #---------------------------------------------------------------------------
    constructor: (@store, @model, @options, @method) ->
        @stepsName = @constructor.name

    #---------------------------------------------------------------------------
    error: (sqlError) ->
        message = "SQL Error #{sqlError.code}: #{sqlError.message}"

        console.log  message
        @options.error message

    #---------------------------------------------------------------------------
    success: (result) ->
        @options.success result

    #---------------------------------------------------------------------------
    model2data: (model) ->
        JSON.stringify(model.toJSON())

    #---------------------------------------------------------------------------
    data2model: (data, model) ->
        modelData = JSON.parse(data)

        if model
            model.set(modelData)
        else
            model = modelData

        model

#-------------------------------------------------------------------------------
class CreateTableThenSyncSteps extends Steps

    #---------------------------------------------------------------------------
    step1: (tx) ->
        tx.executeSql 'CREATE TABLE IF NOT EXISTS store (id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT)'

    #---------------------------------------------------------------------------
    success: ->
        @store.tableCreated = true
        Backbone.sync(@method, @model, @options)

#-------------------------------------------------------------------------------
class CreateSteps extends Steps

    #---------------------------------------------------------------------------
    step1: (tx) ->
        data = @model2data @model
        tx.executeSql 'INSERT INTO store VALUES(NULL, ?)', [data]

    #---------------------------------------------------------------------------
    step2: (tx, sqlError, resultSet) ->
        return if sqlError

        @id = resultSet.insertId

    #---------------------------------------------------------------------------
    success: ->
        @model.id = @id
        super @model

#-------------------------------------------------------------------------------
class ReadSteps extends Steps

    #---------------------------------------------------------------------------
    step1: (tx) ->
        tx.executeSql 'SELECT * FROM store WHERE id=?', [@model.id]

    #---------------------------------------------------------------------------
    step2: (tx, sqlError, resultSet) ->
        return if sqlError

        if resultSet.rows.length != 1
            throw "invalid state: #{resultSet.rows.length} rows with id=#{model.id}"

        row     = resultSet.rows.item(0)
        id      = row.id
        data    = row.data
        data.id = id

        @data = data

    #---------------------------------------------------------------------------
    success: ->
        @data2model @data, @model
        super @model

#-------------------------------------------------------------------------------
class ReadAllSteps extends Steps

    #---------------------------------------------------------------------------
    step1: (tx) ->
        tx.executeSql 'SELECT * FROM store'

    #---------------------------------------------------------------------------
    step2: (tx, sqlError, resultSet) ->
        return if sqlError

        @models = []
        for i in [0...resultSet.rows.length]
            row     = resultSet.rows.item(i)
            id      = row.id
            model   = @data2model row.data
            model.id = id
            @models.push model

    #---------------------------------------------------------------------------
    success: ->
        super @models

#-------------------------------------------------------------------------------
class UpdateSteps extends Steps

    #---------------------------------------------------------------------------
    step1: (tx) ->
        data = @model2data @model
        tx.executeSql 'UPDATE store SET data=? WHERE id=?', [data, @model.id]

    #---------------------------------------------------------------------------
    success: ->
        super @model

#-------------------------------------------------------------------------------
class DeleteSteps extends Steps

    #---------------------------------------------------------------------------
    step1: (tx) ->
        tx.executeSql 'DELETE FROM store WHERE id=?', [@model.id]

    #---------------------------------------------------------------------------
    success: ->
        super @model


