.PHONY: shell
shell: .install.flag
	pipenv shell

.install.flag: setup.cfg
	pipenv install -e .
	touch $@

.PHONY: clean
clean:
	git clean -dX -f
