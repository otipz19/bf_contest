@ECHO OFF
TASM cmp.asm
TLINK cmp
rename %1.com __entry.com
del entry.com >nul
rename __entry.com entry.com
echo Testing...
TESTIT
