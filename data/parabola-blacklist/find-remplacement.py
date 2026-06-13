#!/usr/bin/env python3
# Copyright 2017 Luke Shumaker <lukeshu@parabola.nu>

import pyalpm
import pycman.config

def search(pkgnames):
	pkgnames = set(pkgnames) # for faster set operations
	exact = dict((pkgname,set()) for pkgname in pkgnames)
	suggest = dict((pkgname,set()) for pkgname in pkgnames)

	pycman_options = pycman.config.make_parser().parse_args([])
	handle = pycman.config.init_with_config_and_options(pycman_options)
	dbs = handle.get_syncdbs()
	for db in dbs:
		for pkg in db.search('.*'):
			if pkg.name in pkgnames:
				exact[pkg.name].add(pkg)
			reps = set(pkg.replaces).intersection(pkgnames)
			for pkgname in reps:
				exact[pkgname].add(pkg)
			provs = set([provide.split('=', 1)[0] for provide in pkg.provides]).intersection(pkgnames)
			for pkgname in provs:
				suggest[pkgname].add(pkg)
	return exact, suggest

def main(pkgnames):
	exact, suggest = search(pkgnames)
	for pkgname in pkgnames:
		if len(exact[pkgname]) > 0:
			print(pkgname + ":" + (",".join(sorted([pkg.db.name+"/"+pkg.name for pkg in exact[pkgname]]))))
		elif len(suggest[pkgname]) > 0:
			print(pkgname + ":none:" + (",".join(sorted([pkg.db.name+"/"+pkg.name for pkg in suggest[pkgname]]))))
		else:
			print(pkgname + ":none")

if __name__ == "__main__":
	import sys
	main(sys.argv[1:])