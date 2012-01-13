
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
LibraryName  = WebSQLStepper.name

stepper = new WebSQLStepper()

if module?.exports
   module.exports = stepper
else
   window.WebSQLStepper = stepper

#-------------------------------------------------------------------------------
class Transaction

    #---------------------------------------------------------------------------
    constructor: (@stepper) ->
        @successCB = (tx, resultSet) => @stepper.nextStep(tx, null, resultSet)
        @errorCB   = (tx, sqlError ) => @stepper.nextStep(tx, sqlError, null)

    #---------------------------------------------------------------------------
    executeSql: (sqlStatement, arguments) ->
        @stepper.sqlTx.executeSql(sqlStatement, arguments, @successCB, @errorCB)

#-------------------------------------------------------------------------------
class Stepper

    #---------------------------------------------------------------------------
    constructor: (@db, @steps) ->
        @index   = -1
        @stepFns = @getStepFunctions()

        locus = "initialization"
        if @stepFns.length == 0
            @error "no step# methods found in Steps object", locus

        if typeof @steps.success != 'function'
            @error "no success method found in Steps object", locus

        if typeof @steps.error != 'function'
            @error "no error method found in Steps object", locus

    #---------------------------------------------------------------------------
    run: () ->

        statementCB = (tx)        => @nextStep(tx)
        successCB   = ()          => @txSuccessCB()
        errorCB     = (sqlError ) => @txErrorCB(sqlError)

        @transaction = new Transaction(@)

        @db.transaction(statementCB, errorCB, successCB)

    #---------------------------------------------------------------------------
    nextStep: (@sqlTx, sqlError, resultSet) ->
        @index++

        stepFn = @stepFns[@index]
        return if !stepFn

        try
            stepFn.call(@steps, @transaction, sqlError, resultSet)
        catch e
            @error e, "step#{1+@index}()"

    #---------------------------------------------------------------------------
    txSuccessCB: () ->
        try
            @steps.success.call(@steps)
        catch e
            @error e, 'success()'

    #---------------------------------------------------------------------------
    txErrorCB: (sqlError) ->
        try
            @steps.error.call(@steps, sqlError)
        catch e
            @error e, 'error()'

    #---------------------------------------------------------------------------
    error: (e, locus) ->
        message = "#{LibraryName}: exception during #{@getLocus(locus)}: #{e}"
        console.log message

        stack = e.stack
        console.log stack if stack

        throw e

    #---------------------------------------------------------------------------
    getLocus: (locus) ->
        "#{@getStepperName()}.#{locus}"

    #---------------------------------------------------------------------------
    getStepperName: () ->
        name = @steps.stepsName
        return "#{name}" if name

        name = @steps.constructor.name
        return "#{name}" if name != 'Object'

        return "?"

    #---------------------------------------------------------------------------
    getStepFunctions: () ->
        result = []
        index  = 0

        while true
            index++
            name = "step#{index}"
            fn   = @steps[name]

            break if typeof fn != 'function'

            result.push fn

        result
