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

  var Stepper, Transaction, WebSQLStepper;

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

  Transaction = (function() {

    function Transaction(stepper) {
      var _this = this;
      this.stepper = stepper;
      this.successCB = function(tx, resultSet) {
        return _this.stepper.stSuccessCB(tx, resultSet);
      };
      this.errorCB = function(tx, sqlError) {
        return _this.stepper.stErrorCB(tx, sqlError);
      };
    }

    Transaction.prototype.executeSql = function(sqlStatement, arguments) {
      return this.stepper.sqlTx.executeSql(sqlStatement, arguments, this.successCB, this.errorCB);
    };

    return Transaction;

  })();

  Stepper = (function() {

    function Stepper(db, steps) {
      this.db = db;
      this.steps = steps;
      this.index = -1;
      this.stepFns = this.getStepFunctions();
      if (this.stepFns.length === 0) {
        throw "no step# methods found in Steps object";
      }
      if (typeof this.steps.success !== 'function') {
        throw "no success method found in Steps object";
      }
      if (typeof this.steps.error !== 'function') {
        throw "no error method found in Steps object";
      }
    }

    Stepper.prototype.run = function() {
      var errorCB, statementCB, successCB;
      var _this = this;
      statementCB = function(tx) {
        return _this.stSuccessCB(tx);
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

    Stepper.prototype.stSuccessCB = function(sqlTx, resultSet) {
      return this.nextStep(sqlTx, null, resultSet);
    };

    Stepper.prototype.stErrorCB = function(sqlTx, sqlError) {
      return this.nextStep(sqlTx, sqlError, null);
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
        return this.logException(e, "step" + (1 + this.index));
      }
    };

    Stepper.prototype.txSuccessCB = function() {
      try {
        return this.steps.success.call(this.steps);
      } catch (e) {
        return this.logException(e, 'success');
      }
    };

    Stepper.prototype.txErrorCB = function(sqlError) {
      try {
        return this.steps.error.call(this.steps, sqlError);
      } catch (e) {
        return this.logException(e, 'error');
      }
    };

    Stepper.prototype.logException = function(e, locus) {
      var cn, message;
      cn = this.getStepperClassName();
      message = "exception running " + cn + locus + ": " + e;
      console.log(message);
      throw e;
    };

    Stepper.prototype.getStepperClassName = function() {
      var name;
      name = this.steps.stepsName;
      if (name) return "" + name + ".";
      name = this.steps.constructor.name;
      if (name === 'Object') return "";
      if (name) return "" + name + ".";
      return "";
    };

    Stepper.prototype.getLocus = function() {
      return "" + (getStepperClassName()) + locus;
    };

    Stepper.prototype.getStepFunctions = function() {
      var fn, index, name, result;
      result = [];
      index = 0;
      while (true) {
        index++;
        name = "step" + index;
        fn = this.steps[name];
        if (typeof fn !== 'function') return result;
        result.push(fn);
      }
      return result;
    };

    return Stepper;

  })();

}).call(this);
