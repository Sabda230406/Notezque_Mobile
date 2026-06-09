import sys

def update(file):
    content = open(file, encoding='utf-8').read()
    old_switch = '''            case 3:
              break;'''
    new_switch = '''            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MateriExplorerScreen(),
                ),
              );
              break;'''
    content = content.replace(old_switch, new_switch)
    if 'materi_explorer_screen.dart' not in content:
        content = content.replace('import \'package:flutter/material.dart\';', 'import \'package:flutter/material.dart\';\nimport \'../../materi/screens/materi_explorer_screen.dart\';')
    open(file, 'w', encoding='utf-8').write(content)

update('lib/features/kalender/screens/kalender_screen.dart')
update('lib/features/tugas/screens/kelola_tugas_screen.dart')

