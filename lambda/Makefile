.PHONY: shell
shell: .install.flag
	pipenv shell

.install.flag: pyproject.toml
	pipenv install -e .
	touch $@

.PHONY: clean
clean:
	git clean -dX -f
