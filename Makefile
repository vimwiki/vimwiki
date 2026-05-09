ifdef VERBOSE
override VERBOSE := -v
endif

verbose:
	echo $(VERBOSE)

test:
	cd test; ./run_tests.sh $(VERBOSE) -t vader -n vim_7.3.429 || true
	cd test; ./run_tests.sh $(VERBOSE) -t vader -n vim_8.1.0519 || true
	# TODO add me when test works on Vim, 9.0
	# -- Currently I experienced some surprised due to defaults
	# -- tinmarino 2023-03-10
	# cd test; run_tests.sh $(VERBOSE) -n v9.0.1396
	
	cd test; ./run_tests.sh $(VERBOSE) -t vader -n nvim_0.3.8 || true
	
	# Cannot quote as it is expanded from $OPT after quote removal
	# So I decided to escape the *
	cd test; ./run_tests.sh $(VERBOSE) -t vader -n vim_7.4.1099 -f '[a-k]*.vader' || true
	cd test; ./run_tests.sh $(VERBOSE) -t vader -n vim_7.4.1546 -f 'l*.vader' || true
	cd test; ./run_tests.sh $(VERBOSE) -t vader -n vim_8.0.0027 -f '[m-z]*.vader' || true

.PHONY: test
