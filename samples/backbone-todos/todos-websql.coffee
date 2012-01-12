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

WSS    = WebSQLStepper
Stores = {}

#-------------------------------------------------------------------------------
# similar to original Todo Backbone.sync
#-------------------------------------------------------------------------------
Backbone.sync = (method, model, options) ->

    store = model.localStorage || model.collection.localStorage;

    if not store.tableCreated
        return store.createTable(method, model, options)

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

        wdbName    = "#{@name}DB"
        wdbComment = "#{@name}DB"
        wdbSize    = 1*1024*1024

        @wdb = window.openDatabase(wdbName, '', wdbComment, wdbSize)

        @tableCreated = false

    #---------------------------------------------------------------------------
    createTable: (method, model, options) ->
        store = @

        WSS.transaction @wdb,
            stepsName: 'createTable'

            #----------------------------------
            error: (sqlError) ->
                store.error(sqlError, options)

            #----------------------------------
            step1: (tx) ->
                tx.executeSql 'CREATE TABLE IF NOT EXISTS store (id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT)'

            #----------------------------------
            step2: (tx, sqlError, resultSet) ->
                return if sqlError

            #----------------------------------
            success: ->
                store.tableCreated = true
                Backbone.sync(method, model, options)

    #---------------------------------------------------------------------------
    create: (model, options) ->
        store = @

        WSS.transaction @wdb,
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

    #---------------------------------------------------------------------------
    read: (model, options) ->
        store = @

        WSS.transaction @wdb,
            stepsName: 'read'

            #----------------------------------
            error: (sqlError) ->
                store.error(sqlError, options)

            #----------------------------------
            step1: (tx) ->
                tx.executeSql 'SELECT * FROM store WHERE id=?', [model.id]

            #----------------------------------
            step2: (tx, sqlError, resultSet) ->
                return if sqlError

                if resultSet.rows.length != 1
                    throw "invalid state: #{resultSet.rows.length} rows with id=#{model.id}"

                row     = resultSet.rows.item(0)
                id      = row.id
                data    = row.data
                data.id = id

                @data = data

            #----------------------------------
            success: ->
                model.set(JSON.parse(@data))
                options.success model

    #---------------------------------------------------------------------------
    readAll: (options) ->
        store = @

        WSS.transaction @wdb,
            stepsName: 'readAll'

            #----------------------------------
            error: (sqlError) ->
                store.error(sqlError, options)

            #----------------------------------
            step1: (tx) ->
                tx.executeSql 'SELECT * FROM store'

            #----------------------------------
            step2: (tx, sqlError, resultSet) ->
                return if sqlError

                @items = []
                for i in [0...resultSet.rows.length]
                    row     = resultSet.rows.item(i)
                    id      = row.id
                    data    = JSON.parse(row.data)
                    data.id = id
                    @items.push data

            #----------------------------------
            success: ->
                options.success @items

    #---------------------------------------------------------------------------
    update: (model, options) ->
        store = @

        WSS.transaction @wdb,
            stepsName: 'update'

            #----------------------------------
            error: (sqlError) ->
                store.error(sqlError, options)

            #----------------------------------
            step1: (tx) ->
                data = JSON.stringify(model.toJSON())
                tx.executeSql 'UPDATE store SET data=? WHERE id=?', [data, model.id]

            #----------------------------------
            success: ->
                options.success model

    #---------------------------------------------------------------------------
    delete: (model, options) ->
        store = @

        WSS.transaction @wdb,
            stepsName: 'delete'

            #----------------------------------
            error: (sqlError) ->
                store.error(sqlError, options)

            #----------------------------------
            step1: (tx) ->
                tx.executeSql 'DELETE FROM store WHERE id=?', [model.id]

            #----------------------------------
            success: ->
                options.success model

    #---------------------------------------------------------------------------
    error: (sqlError, options) ->
        if sqlError
            message = "#{sqlError.code}: #{sqlError.message}"
        else
            message = 'unknown error'

        console.log message

        if options.error
            options.error message
        else
            throw message
