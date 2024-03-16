@ECHO OFF
echo.>test.res
echo === test1.b ===>>test.res
entry test1.b >>test.res

echo.>>test.res
echo === test2.b ===>>test.res
echo abcde| entry test2.b >>test.res

echo.>>test.res
echo === test3.b ===>>test.res
echo 58􊌩1| entry test3.b >>test.res

echo.>>test.res
echo === test4.b ===>>test.res
entry test4.b >>test.res

rem Test input which contains BF commands
echo.>>test.res
echo === test5.b ===>>test.res
echo ",.+[+]*- <> 颐栅寓赃虞哐凛"| entry test3.b >>test.res

rem Test BF source which contains characters 'close' to the commands
echo.>>test.res
echo === test6.b ===>>test.res
echo ",.+[+]*- <> 颐栅寓赃虞哐凛"| entry test6.b >>test.res

rem Check if on of the last cells in data[] is realy zero
echo.>>test.res
echo === test7.b ===>>test.res
entry test7.b >>test.res

rem Check if overrun from byte to word and back work
echo.>>test.res
echo === test8.b ===>>test.res
echo 竖| entry test8.b >>test.res

rem Check that tab is not expanded, and chars close to CTRL-Z
echo.>>test.res
echo === test9.b ===>>test.res
entry test2.b <test9.inp >>test.res

rem Check that entry is using words and not bytes
echo.>>test.res
echo === testa.b ===>>test.res
entry testa.b >>test.res

rem Check that input / output with different cell content works
echo.>>test.res
echo === testb.b ===>>test.res
entry testb.b <testb.inp >>test.res

rem Check looooong loops, in order to check small buffers
echo.>>test.res
echo === testc.b ===>>test.res
entry testc.b >>test.res

rem Check short filename and a single line bf source without CRLF
echo.>>test.res
echo === x.b ===>>test.res
entry x.b >>test.res

rem Check long filename and also Ruud's comment
echo.>>test.res
echo === testlong.b ===>>test.res
entry testlong.b >>test.res

rem Check correctness of high byte
echo.>>test.res
echo === testh.b ===>>test.res
echo *|entry.com testh.b >>test.res

fc /b test.res test.ok
