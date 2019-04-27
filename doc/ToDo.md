Interpreter

* Nested Repeat Tag

** Example

<%repeat(2)%>
AAAAAA
<%repeat(1)%>
CCCCCC
<%endrepeat%>
BBBBBB
<%endrepeat%>


* IF equals False with text not working correctly 

<%IF(A=false)%>
ABC
XYZ
<%ENDIF>


* Nested IF Tag