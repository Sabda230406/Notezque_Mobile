import sys
content=open('lib/features/dashboard/screens/dashboard_screen.dart', encoding='utf-8').read()
open('lib/features/dashboard/screens/dashboard_screen.dart','w', encoding='utf-8').write(content.replace('null, // Folder (belum dibuat)', 'const MateriExplorerScreen(),').replace('import \'package:flutter/material.dart\';', 'import \'package:flutter/material.dart\';\nimport \'../../materi/screens/materi_explorer_screen.dart\';'))
