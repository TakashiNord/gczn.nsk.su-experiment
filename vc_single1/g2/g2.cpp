// g2.cpp: определяет точку входа для консольного приложения.
//

#include "stdafx.h"
#include "g2.h"

#include <afxinet.h>

#ifdef _DEBUG
#define new DEBUG_NEW
#endif

unsigned __stdcall gf ( void * );

// Единственный объект приложения

CWinApp theApp;

using namespace std;

int _tmain(int argc, TCHAR* argv[], TCHAR* envp[])
{
	int nRetCode = 0;

	HMODULE hModule = ::GetModuleHandle(NULL);

	if (hModule != NULL)
	{
		// инициализировать MFC, а также печать и сообщения об ошибках про сбое
		if (!AfxWinInit(hModule, NULL, ::GetCommandLine(), 0))
		{
			// TODO: измените код ошибки соответственно своим потребностям
			_tprintf(_T("Критическая ошибка: сбой при инициализации MFC\n"));
			nRetCode = 1;
		}
		else
		{
			// TODO: Вставьте сюда код для приложения.
			
 //unsigned thd_id; // Id потока; здесь не используется
 //_beginthreadex( NULL, 0, &gf, NULL, 0, &thd_id);
   gf(NULL);
 
 
		}
	}
	else
	{
		// TODO: Измените код ошибки соответственно своим потребностям
		_tprintf(_T("Критическая ошибка: неудачное завершение GetModuleHandle\n"));
		nRetCode = 1;
	}

	return nRetCode;
}


unsigned __stdcall gf ( void *p ) {

   //CString url = _T("http://www.gczn.nsk.su/component/helloworld/?regions[0]=401364&regions[1]=401368&regions[2]=401372&regions[3]=401373&regions[4]=401374&regions[5]=401377&regions[6]=401379&regions[7]=401382&regions[8]=401384&regions[9]=401386&regions[10]=417&regions[11]=0&month=0&tip_gilya=0&vacs_datrep=0&ssubmit=%D0%9F%D0%BE%D0%B8%D1%81%D0%BA&start=10");

   CString url = _T("http://www.gczn.nsk.su//?option=com_helloworld&template=gczn_vac&vacancy=7447");
   
   CInternetSession session(_T("GCZN"));
   CHttpConnection* pServer = NULL;
   CHttpFile* pFile = NULL;
   DWORD HttpRequestFlags;

   try
   {
      DWORD dwRet = 0;

      CString strServerName;
      CString strObject;
      INTERNET_PORT nPort = 80;
      DWORD dwServiceType;

      if ( AfxParseURL( url, dwServiceType, strServerName, strObject, nPort ) == 0 )
      {
		printf_s("Error: AfxParseURL did not accept the URL you provided.\r\n");
        return 0;
      }

      printf_s("Server Name = %s \n",strServerName); 
	  printf_s("Object Name  = %s \n",strObject);
      printf_s("Port = %d \n\n",nPort);		

	  HttpRequestFlags = INTERNET_FLAG_EXISTING_CONNECT | INTERNET_FLAG_RELOAD |
                         INTERNET_FLAG_DONT_CACHE | INTERNET_FLAG_NO_AUTO_REDIRECT;

	  pServer = session.GetHttpConnection( strServerName, nPort );
	  pServer->SetOption(INTERNET_OPTION_CONNECT_TIMEOUT, 0xFFFFFFFF);
	  pServer->SetOption(INTERNET_OPTION_CONNECT_RETRIES, 3);
	  pServer->SetOption(INTERNET_OPTION_RECEIVE_TIMEOUT, 120000);

      pFile = pServer->OpenRequest(
            CHttpConnection::HTTP_VERB_GET, strObject, NULL, 1, NULL, NULL,
            HttpRequestFlags
      );	  
	  
	  pFile->AddRequestHeaders( _T( "Accept: */*\r\nUser-Agent: GCZN\r\n" ) );
	  
	  pFile->SendRequest();

	  CString strHeader;
	  pFile->QueryInfo(HTTP_QUERY_RAW_HEADERS_CRLF, strHeader);
	  printf_s("Header = %s\n",strHeader);
      
	  pFile->QueryInfoStatusCode(dwRet);

      if (dwRet == HTTP_STATUS_OK)
      {
         CHAR szBuff[1024];
         while (pFile->Read(szBuff, 1024) > 0)
         {
            printf_s("%1023s", szBuff);
         }
      } else { 
	  
	   CString result;
       if (dwRet == 403) {
        result.Format(_T("Authentication error (HTTP 403)"));
       } else if (dwRet == 404) {
        result.Format(_T("Object not found (HTTP 404)"));
       } else if (dwRet == 500) {
        result.Format(_T("Application error: malformed request (HTTP 500)"));
       } else {
        result.Format(_T("Got unsupported HTTP status code %d"), (int)dwRet);
       }
	 
	 }

	  delete pFile;
      delete pServer;
   }
   catch (CInternetException* pEx)
   {
       //catch errors from WinInet
      TCHAR pszError[64];
      pEx->GetErrorMessage(pszError, 64);
      _tprintf_s(_T("%63s"), pszError);
   }
   session.Close();

   return 0 ;
}