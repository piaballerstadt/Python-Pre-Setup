#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Post install script
"""

from __future__ import unicode_literals

import platform
import sys
import os
import six
import appdirs
from pip.operations import freeze
from io import open

from PySide import QtGui


def main():
    """ run post install routines """
    app = appdirs.AppDirs('Python Installer', 'Unicorn')
    try:
        os.makedirs(app.user_log_dir)
    except:
        pass

    pyversion = platform.python_version()
    pyarch = platform.architecture()[0]

    # log installed python version
    with open(os.path.join(app.user_log_dir, 'install.log'), 'a', encoding='utf-8') as fp:
        fp.write('Python {} ({}) installed.'.format(pyversion, pyarch))

    # log installed modules
    modules = freeze.freeze()
    module_str = ''
    for module in modules:
        module_str += '{}\n'.format(module)
        
    with open(os.path.join(app.user_log_dir, 'modules-py{}-{}.log'.format(pyversion, pyarch)), 'w', encoding='utf-8') as fp:
        fp.write(module_str)

    app = QtGui.QApplication(sys.argv)

    hello = QtGui.QLabel("Python {} ({}) installed".format(pyversion, pyarch))
    hello.show()
    hello.resize(250, 80)
    sys.exit(app.exec_())


if __name__ == '__main__':
    main()
