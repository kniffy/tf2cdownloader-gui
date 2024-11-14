#include <windows.h>
#include <stdio.h>
#include <tchar.h>

//void _tmain( int argc, TCHAR *argv[] )
void _tmain ( )
{
	STARTUPINFO si;
	PROCESS_INFORMATION pi;

	ZeroMemory( &si, sizeof(si) );
	si.cb = sizeof(si);
	ZeroMemory( &pi, sizeof(pi) );

	// Start the child process.
	if( !CreateProcess( "tf2cd.exe",	// the exe name
		NULL,		// Command line args
		NULL,		// Process handle not inheritable
		NULL,		// Thread handle not inheritable
		FALSE,		// Set handle inheritance to FALSE
		CREATE_NO_WINDOW,	// creation flag
		NULL,		// Use parent's environment block
		NULL,		// Use parent's starting directory 
		&si,		// Pointer to STARTUPINFO structure
		&pi )		// Pointer to PROCESS_INFORMATION structure
			)

	{
		printf( "CreateProcess failed (%d).\n", GetLastError() );
		return;
	}

	// Wait until child process exits.
	WaitForSingleObject( pi.hProcess, INFINITE );

	// Close process and thread handles. 
	CloseHandle( pi.hProcess );
	CloseHandle( pi.hThread );
}
