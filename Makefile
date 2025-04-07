menu:
	./menu.sh ./examples/__meta__.menu.yaml

install:
	install -C -v ./menu.sh ~/.local/bin/menu.sh

help:
	@echo "run 'make menu' to launch the installer menu"

###
# dev

clean:
	rm -f var/*menu*.sh

build:
	./bin/build.sh

test: clean build
	./bin/tests.sh

release: test
	cp var/menu.sh .

###
# docs

vhs-demo:
	vhs ./docs/demo.tape

vhs-macro-files:
	vhs ./docs/macro-files.tape
