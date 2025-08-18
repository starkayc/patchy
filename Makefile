.PHONY: build fmt

PROGRAM_NAME=patchy

build:
	crystal build src/$(PROGRAM_NAME).cr -s -p -t --release --error-trace --warnings all
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