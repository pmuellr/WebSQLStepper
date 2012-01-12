###
# Copyright (c) 2012 Patrick Mueller
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###

COFFEE = node_modules/.bin/coffee

#-------------------------------------------------------------------------------
all: help

#-------------------------------------------------------------------------------
build: \
	mkdir_build \
	build_core \
	build_samples
	@echo ----------------------------------------
	@echo build target completed successfully
	@echo ----------------------------------------

#-------------------------------------------------------------------------------
mkdir_build:
	-@rm -rf build
	-@mkdir  build

#-------------------------------------------------------------------------------
build_core:
	-@rm -rf tmp
	-@mkdir  tmp

	$(COFFEE) -c WebSQLStepper.coffee

#-------------------------------------------------------------------------------
build_samples:
	-mkdir build/samples/
	-mkdir build/samples/backbone-todos
	$(COFFEE) -b -c -o build/samples/backbone-todos samples/backbone-todos/*.coffee

#-------------------------------------------------------------------------------
vendor: \
	mkdir_vendor \
	npm_coffee \
	vendor/backbone.js \
	vendor/underscore.js \
	vendor/zepto.js

#-------------------------------------------------------------------------------
mkdir_vendor:
	-@rm -rf vendor
	-@mkdir vendor

#-------------------------------------------------------------------------------
npm_coffee:
	npm install coffee-script@1.1.3

#-------------------------------------------------------------------------------
vendor/backbone.js:
	curl -# -o $@ https://raw.github.com/documentcloud/backbone/0.5.3/backbone.js

	-@mkdir vendor/backbone-todos
	curl -# -o vendor/backbone-todos/destroy.png https://raw.github.com/documentcloud/backbone/0.5.3/examples/todos/destroy.png
	curl -# -o vendor/backbone-todos/index.html  https://raw.github.com/documentcloud/backbone/0.5.3/examples/todos/index.html
	curl -# -o vendor/backbone-todos/todos.css   https://raw.github.com/documentcloud/backbone/0.5.3/examples/todos/todos.css
	curl -# -o vendor/backbone-todos/todos.js    https://raw.github.com/documentcloud/backbone/0.5.3/examples/todos/todos.js
	curl -# -o vendor/backbone-localstorage.js   https://raw.github.com/documentcloud/backbone/0.5.3/examples/backbone-localstorage.js

#-------------------------------------------------------------------------------
vendor/underscore.js:
	curl -# https://raw.github.com/documentcloud/underscore/1.2.3/underscore.js > $@

#-------------------------------------------------------------------------------
vendor/zepto.js:
	-@rm -rf tmp
	-@mkdir  tmp
	curl -# -o tmp/zepto.zip http://zeptojs.com/downloads/zepto-0.8.zip
	unzip -q -d tmp tmp/zepto.zip
	cp tmp/zepto-0.8/dist/zepto.js $@

#-------------------------------------------------------------------------------
help:
	@echo "available targets:"
	@echo "   build   - run a build"
	@echo "   vendor  - get vendor files"
	@echo ""
	@echo "You will need to 'make vendor' before running 'make build'"
