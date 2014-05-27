from os import path
import glob
import re


def rename_mods(line):
    if not re.match('.*Bases.+', line):
        return line, False
    char = type(line)
    new_line = line
    for mod in ('ftdi', 'serial', 'rtv', 'mcdaq'):
        new_line = new_line.replace(char('.{0}._{0}'.format(mod)),
                                    char('.{}'.format(mod)))
    return new_line, new_line != line


doc_path = path.join(path.dirname(path.dirname(path.abspath(__file__))),
                     'build', 'html')
files = glob.glob('{}{}*.html'.format(doc_path, path.sep))

print('Starting post-processing html files.')

for f in files:
    f = path.abspath(f)
    with open(f) as fhd:
        lines = [line for line in fhd]

    changed = False
    for i in range(len(lines)):
        lines[i], ch = rename_mods(lines[i])
        changed = changed or ch

    if changed:
        print('Editing {}.'.format(path.split(f)[1]))
        with open(f, 'w') as fhd:
            for line in lines:
                fhd.write(line)

print('Done post-processing html files.')
