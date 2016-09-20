#!/bin/bash
#
# Apply patches in the same directory as the script, to the current working
# directory, trying first patchlevel 0, then 1 (allows manual processing of
# .patch files that have been set up for compatibility with Gentoo's unipatch)
#
# Copyright (c) 2016 sakaki <sakaki@deciban.com>
#
# License (GPL v3.0)
# ------------------
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

PATCHDIR="$(dirname "$(readlink -f "${0}")")"
APPLYDIR="${PWD}"

for P in "${PATCHDIR}/"*.patch; do
	echo -n "Apply: $(basename "${P}") "
	# try first at patchlevel 0, per unipatch
	for PL in 0 1 2; do
		if ((PL==2)); then
			echo "FAIL"
			>&2 echo "Patch failed on dry run, exiting"
			exit 1
		fi
		if patch -p${PL} -fN --dry-run <"${P}" &>/dev/null; then
			if patch -p${PL} -fN <"${P}" &>/dev/null; then
				echo "(${PL}) OK"
				break
			else
				# shouldn't really happen, but...
				echo "FAIL"
				>&2 echo "Patch failed on application, exiting"
				exit 1
			fi
		fi
	done
done
echo "All patches applied successfully!"