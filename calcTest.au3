#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
#include <FileConstants.au3>
#include <File.au3>
#include <StringConstants.au3>
#include <MsgBoxConstants.au3>
#include <ScreenCapture.au3>

Global Const $TEST_CASES_FILE_NAME = "testCases.txt"
Global Const $LOG_FILE_ERROR_MESSAGE = "An error occurred when creating or reading the file "
Global Const $EARLY_EXIT_ERROR_MESSAGE = "An error has caused the script to exit early. For detailed logs, please see log file: "
Global Const $PROGRAM_NAME = "calc.exe"
Global Const $PROGRAM_TITLE = "Calculator"
Global Const $TIMEOUT = 10

TestCalc()

Func TestCalc()
	;open log file, create if it doesn't exist
	Local $logFilePrefix = @YEAR & "_" & @MON & "_" & @MDAY & "_" & @HOUR & "_" & @MIN & "_" & @SEC & "_"
	Local $logDirectory = $logFilePrefix & "\"
	Local $logFileName = $logDirectory & $logFilePrefix & "log.txt"
	Local $logFileHandler = FileOpen("logs\" & $logFileName , $FO_APPEND + $FO_CREATEPATH)
	If $logFileHandler = -1 Then
		MsgBox($MB_SYSTEMMODAL, "", $LOG_FILE_ERROR_MESSAGE & $logFileName & "." & @CRLF)
		Return False
	EndIf

	;open test cases file
	Local $testCasesFileHandler = FileOpen($TEST_CASES_FILE_NAME, $FO_READ)
	If $testCasesFileHandler = -1 Then
		_FileWriteLog($logFileHandler, "An error occurred when reading the file " & $TEST_CASES_FILE_NAME & "." & @CRLF)
		MsgBox($MB_SYSTEMMODAL, "", $EARLY_EXIT_ERROR_MESSAGE & $logFileName & "." & @CRLF)
		Return False
	Else
		_FileWriteLog($logFileHandler, "Read file " & $TEST_CASES_FILE_NAME & " successfully." & @CRLF)
	EndIf

	;open calculator app
	Run($PROGRAM_NAME)
	_FileWriteLog($logFileHandler, "Started " & $PROGRAM_NAME & "." & @CRLF)
	Local $hWnd = WinWaitActive($PROGRAM_TITLE, "", $TIMEOUT)
	If $hWnd = 0 Then
		_FileWriteLog($logFileHandler, "Open operation timed out when opening " & $PROGRAM_NAME & "." & @CRLF)
		MsgBox($MB_SYSTEMMODAL, "", $EARLY_EXIT_ERROR_MESSAGE & $logFileName & "." & @CRLF)
		Return False
	Else
		_FileWriteLog($logFileHandler, "Opened file " & $PROGRAM_NAME & " successfully." & @CRLF)
	EndIf

	;standard mode
	Send("!1")

	For $i = 1 To _FileCountLines($TEST_CASES_FILE_NAME)
		$line = FileReadLine($testCasesFileHandler, $i)
		If @error = 1 Then
			_FileWriteLog($logFileHandler, "An error occurred when reading the file " & $TEST_CASES_FILE_NAME & " at line " & $i & "." & @CRLF)
		ElseIf @error = -1 Then
			_FileWriteLog($logFileHandler, "End of file " & $TEST_CASES_FILE_NAME & " reached at line " & $i & "." & @CRLF)
		EndIf

		If Not(@error = 0) Then
			MsgBox($MB_SYSTEMMODAL, "", $EARLY_EXIT_ERROR_MESSAGE & $logFileName & "." & @CRLF)
			Return False
		EndIf

		_FileWriteLog($logFileHandler, "Reading line " & $i & "." & @CRLF)

		$testCaseLabelPos = StringInStr($line, ":")
		If $testCaseLabelPos = 0 Then
			_FileWriteLog($logFileHandler, "Test case label and ':' not found in line " & $i & "." & @CRLF)
			MsgBox($MB_SYSTEMMODAL, "", $EARLY_EXIT_ERROR_MESSAGE & $logFileName & "." & @CRLF)
			Return False
		EndIf

		If @error = 1 Then
			_FileWriteLog($logFileHandler, "Invalid parameters given to StringInStr." & @CRLF)
			MsgBox($MB_SYSTEMMODAL, "", $EARLY_EXIT_ERROR_MESSAGE & $logFileName & "." & @CRLF)
			Return False
		EndIf

		$testCaseLabel = StringMid($line, 1, $testCaseLabelPos)

		$equation = StringMid($line, $testCaseLabelPos + 1)

		$equalSignPos = StringInStr($equation, "=")
		If $equalSignPos = 0 Then
			_FileWriteLog($logFileHandler, "Equal sign ('=') not found in line " & $i & "." & @CRLF)
			MsgBox($MB_SYSTEMMODAL, "", $EARLY_EXIT_ERROR_MESSAGE & $logFileName & "." & @CRLF)
			Return False
		EndIf

		If @error = 1 Then
			_FileWriteLog($logFileHandler, "Invalid parameters given to StringInStr." & @CRLF)
			MsgBox($MB_SYSTEMMODAL, "", $EARLY_EXIT_ERROR_MESSAGE & $logFileName & "." & @CRLF)
			Return False
		EndIf

		Local $leftHandSide = StringStripWS(StringMid($equation, 1, $equalSignPos), $STR_STRIPALL)
		Local $rightHandSide = StringStripWS(StringMid($equation, $equalSignPos + 1), $STR_STRIPALL)

		_FileWriteLog($logFileHandler, $testCaseLabel & @CRLF)
		Local $escapedString = StringRegExpReplace($leftHandSide, "([\^\+{}])", "{$1}");StringReplace($leftHandSide, "{", "{{}")

		Send($escapedString)
		_FileWriteLog($logFileHandler, $leftHandSide & @CRLF)
		_FileWriteLog($logFileHandler, "Escaped string: " & $escapedString & @CRLF)
		Send("^c")
		Local $result = ClipGet()

		_FileWriteLog($logFileHandler, "Expected: " & $rightHandSide & "; Actual: " & $result & @CRLF)
		Local $success = "success"
		If Not(StringCompare($result, $rightHandSide) = 0) Then
			$success = "failed"
		EndIf
		_FileWriteLog($logFileHandler, "Test result: " & $success & @CRLF)
		$Image = _ScreenCapture_CaptureWnd ( "", $hWnd )
		$ImageFileName = $logFilePrefix & $i & "_ss.jpg"
		_ScreenCapture_SaveImage ("logs\" & $logDirectory & $ImageFileName , $Image, True )
		_FileWriteLog($logFileHandler, "Screen shot saved in " & $ImageFileName & @CRLF)
	Next
	FileClose($testCasesFileHandler)

	WinClose($hWnd)
EndFunc		;end of TestCalc

