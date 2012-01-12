
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
class WebSQLStepper

    #---------------------------------------------------------------------------
    transaction: (db, steps) ->
        stepper = new Stepper(db, steps)
        stepper.run()

#-------------------------------------------------------------------------------
window.WebSQLStepper = new WebSQLStepper()

#-------------------------------------------------------------------------------
class Transaction

    #---------------------------------------------------------------------------
    constructor: (@stepper) ->
        @successCB = (tx, resultSet) => @stepper.stSuccessCB(tx, resultSet)
        @errorCB   = (tx, sqlError ) => @stepper.stErrorCB(tx, sqlError)

    #---------------------------------------------------------------------------
    executeSql: (sqlStatement, arguments) ->
        @stepper.sqlTx.executeSql(sqlStatement, arguments, @successCB, @errorCB)

#-------------------------------------------------------------------------------
class Stepper

    #---------------------------------------------------------------------------
    constructor: (@db, @steps) ->
        @index   = -1
        @stepFns = @getStepFunctions()

        if @stepFns.length == 0
            throw "no step# methods found in Steps object"

        if typeof @steps.success != 'function'
            throw "no success method found in Steps object"

        if typeof @steps.error != 'function'
            throw "no error method found in Steps object"


    #---------------------------------------------------------------------------
    run: () ->

        statementCB = (tx)        => @stSuccessCB(tx)
        successCB   = ()          => @txSuccessCB()
        errorCB     = (sqlError ) => @txErrorCB(sqlError)

        @transaction = new Transaction(@)

        @db.transaction(statementCB, errorCB, successCB)

    #---------------------------------------------------------------------------
    stSuccessCB: (sqlTx, resultSet) ->
        @nextStep(sqlTx, null, resultSet)

    #---------------------------------------------------------------------------
    stErrorCB: (sqlTx, sqlError) ->
        @nextStep(sqlTx, sqlError, null)

    #---------------------------------------------------------------------------
    nextStep: (@sqlTx, sqlError, resultSet) ->
        @index++

        stepFn = @stepFns[@index]
        return if !stepFn

        try
            stepFn.call(@steps, @transaction, sqlError, resultSet)
        catch e
            @logException e, "step#{1+@index}"

    #---------------------------------------------------------------------------
    txSuccessCB: () ->
        try
            @steps.success.call(@steps)
        catch e
            @logException e, 'success'

    #---------------------------------------------------------------------------
    txErrorCB: (sqlError) ->
        try
            @steps.error.call(@steps, sqlError)
        catch e
            @logException e, 'error'

    #---------------------------------------------------------------------------
    logException: (e, locus) ->
        cn = @getStepperClassName()
        message = "exception running #{cn}#{locus}: #{e}"
        console.log message
        throw e

    #---------------------------------------------------------------------------
    getStepperClassName: () ->
        name = @steps.stepsName
        return "#{name}." if name

        name = @steps.constructor.name
        return "" if name == 'Object'

        return "#{name}." if name

        return ""

    #---------------------------------------------------------------------------
    getLocus: () ->
        "#{getStepperClassName()}#{locus}"

    #---------------------------------------------------------------------------
    getStepFunctions: () ->
        result = []
        index  = 0

        while true
            index++
            name = "step#{index}"
            fn   = @steps[name]

            return result if typeof fn != 'function'

            result.push fn

        result
