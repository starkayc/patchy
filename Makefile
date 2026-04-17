.PHONY: build build-static run fmt typer clean

PROGRAM_NAME=patchy

ESBUILD := $(shell command -v esbuild 2>/dev/null)

build:
ifeq ($(ESBUILD),)
	crystal build src/$(PROGRAM_NAME).cr -s -p -t --release --error-trace --warnings all
else
	@echo "Minifying JS files"
	esbuild "./public/-/assets/js/*" --color=false --sourcemap --minify --outdir="./public/-/assets/js-m"
	crystal build src/$(PROGRAM_NAME).cr -s -p -t --release --error-trace --warnings all -Dpatchy_minified_js
endif

build-static:
	crystal build src/$(PROGRAM_NAME).cr -s -p -t --release --error-trace --warnings all --static
run:
	crystal build src/$(PROGRAM_NAME).cr -s -p -t -d --error-trace
	./$(PROGRAM_NAME)
fmt:
	crystal tool format ./src
typer:
	./bin/typer --progress --stats ./src/$(PROGRAM_NAME).cr src
clean:
	rm -rf data
	rm -f patchy
