menu:
	./menu.sh ./examples/__meta__.menu.yaml

install:
	install -C -v ./menu.sh ~/.local/bin/menu.sh

test:
	./tests.sh

help:
	@echo "just run 'make menu'"
