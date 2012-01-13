(function() {

  /*
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
  */

  var LibraryName, Stepper, Transaction, WebSQLStepper;

  WebSQLStepper = (function() {

    function WebSQLStepper() {}

    WebSQLStepper.prototype.transaction = function(db, steps) {
      var stepper;
      stepper = new Stepper(db, steps);
      return stepper.run();
    };

    return WebSQLStepper;

  })();

  window.WebSQLStepper = new WebSQLStepper();

  LibraryName = WebSQLStepper.name;

  Transaction = (function() {

    function Transaction(stepper) {
      var _this = this;
      this.stepper = stepper;
      this.successCB = function(tx, resultSet) {
        return _this.stepper.nextStep(tx, null, resultSet);
      };
      this.errorCB = function(tx, sqlError) {
        return _this.stepper.nextStep(tx, sqlError, null);
      };
    }

    Transaction.prototype.executeSql = function(sqlStatement, arguments) {
      return this.stepper.sqlTx.executeSql(sqlStatement, arguments, this.successCB, this.errorCB);
    };

    return Transaction;

  })();

  Stepper = (function() {

    function Stepper(db, steps) {
      var locus;
      this.db = db;
      this.steps = steps;
      this.index = -1;
      this.stepFns = this.getStepFunctions();
      locus = "initialization";
      if (this.stepFns.length === 0) {
        this.error("no step# methods found in Steps object", locus);
      }
      if (typeof this.steps.success !== 'function') {
        this.error("no success method found in Steps object", locus);
      }
      if (typeof this.steps.error !== 'function') {
        this.error("no error method found in Steps object", locus);
      }
    }

    Stepper.prototype.run = function() {
      var errorCB, statementCB, successCB;
      var _this = this;
      statementCB = function(tx) {
        return _this.nextStep(tx);
      };
      successCB = function() {
        return _this.txSuccessCB();
      };
      errorCB = function(sqlError) {
        return _this.txErrorCB(sqlError);
      };
      this.transaction = new Transaction(this);
      return this.db.transaction(statementCB, errorCB, successCB);
    };

    Stepper.prototype.nextStep = function(sqlTx, sqlError, resultSet) {
      var stepFn;
      this.sqlTx = sqlTx;
      this.index++;
      stepFn = this.stepFns[this.index];
      if (!stepFn) return;
      try {
        return stepFn.call(this.steps, this.transaction, sqlError, resultSet);
      } catch (e) {
        return this.error(e, "step" + (1 + this.index) + "()");
      }
    };

    Stepper.prototype.txSuccessCB = function() {
      try {
        return this.steps.success.call(this.steps);
      } catch (e) {
        return this.error(e, 'success()');
      }
    };

    Stepper.prototype.txErrorCB = function(sqlError) {
      try {
        return this.steps.error.call(this.steps, sqlError);
      } catch (e) {
        return this.error(e, 'error()');
      }
    };

    Stepper.prototype.error = function(e, locus) {
      var message, stack;
      message = "" + LibraryName + ": exception during " + (this.getLocus(locus)) + ": " + e;
      console.log(message);
      stack = e.stack;
      if (stack) console.log(stack);
      throw e;
    };

    Stepper.prototype.getLocus = function(locus) {
      return "" + (this.getStepperName()) + "." + locus;
    };

    Stepper.prototype.getStepperName = function() {
      var name;
      name = this.steps.stepsName;
      if (name) return "" + name;
      name = this.steps.constructor.name;
      if (name !== 'Object') return "" + name;
      return "?";
    };

    Stepper.prototype.getStepFunctions = function() {
      var fn, index, name, result;
      result = [];
      index = 0;
      while (true) {
        index++;
        name = "step" + index;
        fn = this.steps[name];
        if (typeof fn !== 'function') break;
        result.push(fn);
      }
      return result;
    };

    return Stepper;

  })();

}).call(this);
