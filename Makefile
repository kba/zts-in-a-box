lib: src/lib
	coffee -o "$@" "$<"

test: src/test
	coffee -o "$@" "$<"

clean:
	@rm -rf lib test
